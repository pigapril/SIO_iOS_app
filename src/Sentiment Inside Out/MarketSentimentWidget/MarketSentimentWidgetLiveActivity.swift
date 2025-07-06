//
//  MarketSentimentWidgetLiveActivity.swift
//  MarketSentimentWidget
//
//  Created by Tony Huang on 2025/7/6.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MarketSentimentWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MarketSentimentWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MarketSentimentWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MarketSentimentWidgetAttributes {
    fileprivate static var preview: MarketSentimentWidgetAttributes {
        MarketSentimentWidgetAttributes(name: "World")
    }
}

extension MarketSentimentWidgetAttributes.ContentState {
    fileprivate static var smiley: MarketSentimentWidgetAttributes.ContentState {
        MarketSentimentWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MarketSentimentWidgetAttributes.ContentState {
         MarketSentimentWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MarketSentimentWidgetAttributes.preview) {
   MarketSentimentWidgetLiveActivity()
} contentStates: {
    MarketSentimentWidgetAttributes.ContentState.smiley
    MarketSentimentWidgetAttributes.ContentState.starEyes
}
