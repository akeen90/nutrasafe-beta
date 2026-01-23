"""
NutraSafe Image Background Removal Service
Uses rembg for high-quality background removal
Includes auto-straightening for tilted products
Deployed on Cloud Run for better ML performance
"""

import os
import io
import base64
import math
from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from rembg import remove, new_session
from PIL import Image
import numpy as np

# Try to import OpenCV for straightening
try:
    import cv2
    OPENCV_AVAILABLE = True
except ImportError:
    OPENCV_AVAILABLE = False
    print("OpenCV not available - straightening disabled")

# Initialize rembg session with isnet-general-use model (better for products)
# This model is more conservative and preserves more detail
try:
    REMBG_SESSION = new_session("isnet-general-use")
    print("Using isnet-general-use model for better product detection")
except Exception as e:
    print(f"Failed to load isnet-general-use, falling back to default: {e}")
    REMBG_SESSION = None

app = Flask(__name__)
CORS(app, origins=[
    'http://localhost:*',
    'https://nutrasafe-705c7.web.app',
    'https://nutrasafe-705c7.firebaseapp.com',
])


def straighten_image(pil_image, max_angle=45):
    """
    Straighten a product image by detecting the main object and rotating to align it.

    Args:
        pil_image: PIL Image with transparent background
        max_angle: Maximum rotation angle to apply (to avoid over-rotation)

    Returns:
        Straightened PIL Image
    """
    if not OPENCV_AVAILABLE:
        print("OpenCV not available for straightening")
        return pil_image

    try:
        # Convert PIL to OpenCV format
        img_array = np.array(pil_image)

        # Check if image has alpha channel
        if len(img_array.shape) < 3 or img_array.shape[2] != 4:
            print("Image doesn't have alpha channel, skipping straighten")
            return pil_image

        # Get alpha channel as mask
        alpha = img_array[:, :, 3]

        # Threshold to get binary mask
        _, binary_mask = cv2.threshold(alpha, 10, 255, cv2.THRESH_BINARY)

        # Apply morphological operations to clean up the mask
        kernel = np.ones((5, 5), np.uint8)
        binary_mask = cv2.morphologyEx(binary_mask, cv2.MORPH_CLOSE, kernel)
        binary_mask = cv2.morphologyEx(binary_mask, cv2.MORPH_OPEN, kernel)

        # Find contours
        contours, _ = cv2.findContours(binary_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if not contours:
            print("No contours found")
            return pil_image

        # Find the largest contour (the main product)
        largest_contour = max(contours, key=cv2.contourArea)

        # Check if contour is large enough to be meaningful
        contour_area = cv2.contourArea(largest_contour)
        image_area = img_array.shape[0] * img_array.shape[1]
        if contour_area < image_area * 0.05:  # Less than 5% of image
            print(f"Contour too small: {contour_area} vs {image_area}")
            return pil_image

        # Get minimum area bounding rectangle
        rect = cv2.minAreaRect(largest_contour)
        center, (rect_width, rect_height), angle = rect

        print(f"Detected rect: width={rect_width:.1f}, height={rect_height:.1f}, angle={angle:.1f}")

        # minAreaRect returns angle in range [-90, 0)
        # angle is the rotation of the rectangle from horizontal

        # Determine the rotation needed to make the product upright
        # For products like bottles/boxes, we want the longer side vertical
        if rect_width > rect_height:
            # Rectangle is wider than tall, so it's rotated
            # We need to rotate by (angle + 90) to make the long side vertical
            rotation_angle = angle + 90
        else:
            # Rectangle is already taller than wide
            rotation_angle = angle

        # Normalize angle to [-45, 45] range
        while rotation_angle > 45:
            rotation_angle -= 90
        while rotation_angle < -45:
            rotation_angle += 90

        print(f"Calculated rotation angle: {rotation_angle:.1f} degrees")

        # Only rotate if the angle is significant (> 1 degree) but not too extreme
        if abs(rotation_angle) < 1:
            print("Angle too small, skipping rotation")
            return pil_image

        if abs(rotation_angle) > max_angle:
            print(f"Angle {rotation_angle} exceeds max {max_angle}, skipping")
            return pil_image

        # Get image dimensions
        h, w = img_array.shape[:2]
        center_point = (w / 2, h / 2)

        # Calculate new dimensions to fit rotated image
        angle_rad = math.radians(abs(rotation_angle))
        new_w = int(w * math.cos(angle_rad) + h * math.sin(angle_rad)) + 2
        new_h = int(h * math.cos(angle_rad) + w * math.sin(angle_rad)) + 2

        # Create rotation matrix
        rotation_matrix = cv2.getRotationMatrix2D(center_point, rotation_angle, 1.0)

        # Adjust translation to center the rotated image
        rotation_matrix[0, 2] += (new_w - w) / 2
        rotation_matrix[1, 2] += (new_h - h) / 2

        # Apply rotation with transparent background
        rotated = cv2.warpAffine(
            img_array,
            rotation_matrix,
            (new_w, new_h),
            flags=cv2.INTER_LINEAR,
            borderMode=cv2.BORDER_CONSTANT,
            borderValue=(0, 0, 0, 0)
        )

        print(f"Successfully rotated image by {rotation_angle:.1f} degrees")

        # Convert back to PIL
        return Image.fromarray(rotated)

    except Exception as e:
        print(f"Straightening error: {e}")
        import traceback
        traceback.print_exc()
        return pil_image


def crop_to_content(pil_image, padding=10):
    """
    Crop image to content bounds with optional padding.

    Args:
        pil_image: PIL Image with transparent background
        padding: Pixels of padding around content

    Returns:
        Cropped PIL Image
    """
    try:
        # Get alpha channel
        if pil_image.mode != 'RGBA':
            return pil_image

        # Get bounding box of non-transparent pixels
        bbox = pil_image.getbbox()

        if not bbox:
            return pil_image

        # Add padding
        left = max(0, bbox[0] - padding)
        top = max(0, bbox[1] - padding)
        right = min(pil_image.width, bbox[2] + padding)
        bottom = min(pil_image.height, bbox[3] + padding)

        # Crop
        return pil_image.crop((left, top, right, bottom))

    except Exception as e:
        print(f"Crop error: {e}")
        return pil_image


# Health check endpoint
@app.route('/', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'service': 'rembg-background-removal',
        'features': {
            'straightening': OPENCV_AVAILABLE,
            'cropping': True
        }
    })


@app.route('/remove-background', methods=['POST'])
def remove_background():
    """
    Remove background from an image.

    Accepts either:
    - JSON body with 'imageUrl' field (fetches the image)
    - JSON body with 'imageData' field (base64 encoded image)

    Optional parameters:
    - 'straighten': boolean (default: true) - auto-straighten tilted products
    - 'crop': boolean (default: true) - crop to content bounds

    Returns:
    - JSON with 'success', 'imageData' (base64 PNG with transparency)
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'success': False, 'error': 'No JSON body provided'}), 400

        input_image = None
        do_straighten = data.get('straighten', True)
        do_crop = data.get('crop', True)

        # Option 1: Fetch from URL
        if 'imageUrl' in data:
            url = data['imageUrl']
            try:
                response = requests.get(url, timeout=30)
                response.raise_for_status()
                input_image = Image.open(io.BytesIO(response.content))
            except Exception as e:
                return jsonify({'success': False, 'error': f'Failed to fetch image: {str(e)}'}), 400

        # Option 2: Base64 encoded image data
        elif 'imageData' in data:
            try:
                # Handle data URL format (data:image/...;base64,...)
                image_data = data['imageData']
                if ',' in image_data:
                    image_data = image_data.split(',')[1]

                image_bytes = base64.b64decode(image_data)
                input_image = Image.open(io.BytesIO(image_bytes))
            except Exception as e:
                return jsonify({'success': False, 'error': f'Failed to decode image: {str(e)}'}), 400

        else:
            return jsonify({'success': False, 'error': 'Provide either imageUrl or imageData'}), 400

        # Convert to RGB if necessary (rembg works best with RGB)
        if input_image.mode in ('RGBA', 'LA', 'P'):
            # Keep alpha if present, otherwise convert to RGB
            if input_image.mode == 'P':
                input_image = input_image.convert('RGBA')
        elif input_image.mode != 'RGB':
            input_image = input_image.convert('RGB')

        # Remove background using rembg
        # IMPORTANT: Alpha matting disabled - it's too aggressive and cuts into products
        # The isnet-general-use model already provides clean edges
        output_image = remove(
            input_image,
            session=REMBG_SESSION,
            alpha_matting=False,  # Disabled - was cutting products
        )

        # Auto-straighten if enabled
        if do_straighten and OPENCV_AVAILABLE:
            output_image = straighten_image(output_image)

        # Crop to content if enabled
        if do_crop:
            output_image = crop_to_content(output_image)

        # Convert to PNG with transparency
        output_buffer = io.BytesIO()
        output_image.save(output_buffer, format='PNG', optimize=True)
        output_buffer.seek(0)

        # Encode as base64
        output_base64 = base64.b64encode(output_buffer.getvalue()).decode('utf-8')

        return jsonify({
            'success': True,
            'imageData': f'data:image/png;base64,{output_base64}',
            'width': output_image.width,
            'height': output_image.height,
            'straightened': do_straighten and OPENCV_AVAILABLE,
            'cropped': do_crop,
        })

    except Exception as e:
        print(f'Error processing image: {str(e)}')
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/remove-background-batch', methods=['POST'])
def remove_background_batch():
    """
    Remove background from multiple images.

    Accepts JSON body with 'images' array containing:
    - Objects with 'id' and either 'imageUrl' or 'imageData'

    Optional parameters:
    - 'straighten': boolean (default: true) - auto-straighten tilted products
    - 'crop': boolean (default: true) - crop to content bounds

    Returns:
    - JSON with 'results' array containing processed images
    """
    try:
        data = request.get_json()

        if not data or 'images' not in data:
            return jsonify({'success': False, 'error': 'Provide images array'}), 400

        images = data['images']
        if len(images) > 10:
            return jsonify({'success': False, 'error': 'Maximum 10 images per batch'}), 400

        do_straighten = data.get('straighten', True)
        do_crop = data.get('crop', True)

        results = []

        for item in images:
            item_id = item.get('id', 'unknown')
            try:
                input_image = None

                if 'imageUrl' in item:
                    response = requests.get(item['imageUrl'], timeout=30)
                    response.raise_for_status()
                    input_image = Image.open(io.BytesIO(response.content))
                elif 'imageData' in item:
                    image_data = item['imageData']
                    if ',' in image_data:
                        image_data = image_data.split(',')[1]
                    image_bytes = base64.b64decode(image_data)
                    input_image = Image.open(io.BytesIO(image_bytes))
                else:
                    results.append({'id': item_id, 'success': False, 'error': 'No image provided'})
                    continue

                # Convert mode if needed
                if input_image.mode == 'P':
                    input_image = input_image.convert('RGBA')
                elif input_image.mode not in ('RGB', 'RGBA', 'LA'):
                    input_image = input_image.convert('RGB')

                # Remove background - no alpha matting (too aggressive)
                output_image = remove(
                    input_image,
                    session=REMBG_SESSION,
                    alpha_matting=False,
                )

                # Auto-straighten if enabled
                if do_straighten and OPENCV_AVAILABLE:
                    output_image = straighten_image(output_image)

                # Crop to content if enabled
                if do_crop:
                    output_image = crop_to_content(output_image)

                # Encode as base64
                output_buffer = io.BytesIO()
                output_image.save(output_buffer, format='PNG', optimize=True)
                output_buffer.seek(0)
                output_base64 = base64.b64encode(output_buffer.getvalue()).decode('utf-8')

                results.append({
                    'id': item_id,
                    'success': True,
                    'imageData': f'data:image/png;base64,{output_base64}',
                    'width': output_image.width,
                    'height': output_image.height,
                })

            except Exception as e:
                results.append({'id': item_id, 'success': False, 'error': str(e)})

        return jsonify({
            'success': True,
            'results': results,
            'processed': len([r for r in results if r['success']]),
            'failed': len([r for r in results if not r['success']]),
        })

    except Exception as e:
        print(f'Error processing batch: {str(e)}')
        return jsonify({'success': False, 'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
