//
//  ContentView.swift
//  TestIJKDemo
//
//  Test view for IJK Player
//

import SwiftUI

struct ContentView: View {
    // Updated RTMPS URL for new stream
    private let streamURL = "rtmps://live.cloudflare.com:443/live/32bf6b62713da7522f6efb2bc1cc8b45kf1285f49cb4972fa187f452d58d73b96"
    
    var body: some View {
        NavigationView {
            VStack {
                Text("IJK Player Test")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                Text("Testing RTMPS Stream")
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                IJKPlayerView(url: streamURL)
                    .aspectRatio(16/9, contentMode: .fit)
                    .background(Color.black)
                    .cornerRadius(8)
                    .padding()
                
                Text("Stream URL:")
                    .foregroundColor(.white)
                    .font(.caption)
                
                Text(streamURL)
                    .foregroundColor(.blue)
                    .font(.caption)
                    .padding()
                
                Spacer()
            }
            .background(Color.black)
            .navigationTitle("IJK Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
} 