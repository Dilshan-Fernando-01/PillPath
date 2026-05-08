
import SwiftUI

extension View {

    
    func pillPathFont(_ style: Font.TextStyle) -> some View {
        self.font(Font.system(style))
    }

   
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide { self.hidden() } else { self }
    }
}
