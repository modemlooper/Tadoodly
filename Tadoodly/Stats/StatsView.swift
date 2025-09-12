//
//  StatsView.swift
//  Tadoodly
//
//  Created by modemlooper on 6/4/25.
//

import Foundation
import SwiftUI
import SwiftData

struct StatsView: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .light ? Color(.systemGray6) : Color.clear)
                .ignoresSafeArea()

            ScrollView {
                
                LineChartView()
                    .padding(.horizontal)
           
                Grid {
        
                    GridRow {
                        CircleChartView()
                            .frame(maxHeight: .infinity)
                        TotalTimeView()
                            .frame(maxHeight: .infinity)
                    }
                    
                    DailyAverageView()
                }
                .padding(.horizontal)
               
            }
         
            .scrollIndicators(.hidden)
            .navigationTitle("Statistics")
            .toolbar {
            }
        }
    }
    
}
