import SwiftUI

struct TestLiveScannerView: View {
    @State private var showingScanner = false
    @State private var scannedText = "No text scanned yet"
    @State private var scannedData: [String: Any]?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Live Scanner Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                Button("Start Live Scanner") {
                    showingScanner = true
                }
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Last Scanned Text:")
                        .font(.headline)
                    
                    ScrollView {
                        Text(scannedText)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                    
                    if let data = scannedData {
                        Text("Structured Data:")
                            .font(.headline)
                        
                        ForEach(Array(data.keys.sorted()), id: \.self) { key in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(key.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("\(data[key] ?? "N/A")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scanner Test")
            .sheet(isPresented: $showingScanner) {
                LiveIngredientScannerView { text, data in
                    scannedText = text
                    scannedData = data
                }
            }
        }
    }
}

#Preview {
    TestLiveScannerView()
}