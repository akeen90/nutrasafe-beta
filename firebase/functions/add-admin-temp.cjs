const admin = require('firebase-admin');

// Initialize with default credentials
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: 'nutrasafe-705c7'
    });
}

const db = admin.firestore();

async function addAdmin() {
    const uid = 'dM0rqAAVhjRcfFhAYtkJ6AFOd9j2';
    const email = 'aaronmkeen@gmail.com';
    
    await db.collection('admins').doc(uid).set({
        email: email,
        addedAt: admin.firestore.FieldValue.serverTimestamp(),
        role: 'admin'
    });
    
    console.log(`Added ${email} (${uid}) to /admins collection`);
}

addAdmin().then(() => process.exit(0)).catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
});
