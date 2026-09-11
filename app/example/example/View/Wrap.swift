//
//  Wrap.swift
//  SwiftUITemplet
//
//  Created by Bin Shang on 2025/2/27.
//

import SwiftUI


//Wrap(spacing: 10,
//      runSpacing: 10,
//      alignment: .leading) {
//    ForEach(0..<20) { i in
//        Text("选项_\(i)\("z" * i)")
//            .padding(EdgeInsets.symmetric(
//                horizontal: 8,
//                vertical: 4))
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(8)
//            .onTapGesture { p in
//                DDLog("onTapGesture: \(i)")
//            }
//    }
//}
//.padding(10)

/// 折行布局
struct Wrap: Layout {
    /// 水平间距
    var spacing: CGFloat
    /// 竖直间距
    var runSpacing: CGFloat
    /// 对齐方式
    var alignment: HorizontalAlignment

    init(spacing: CGFloat = 10, runSpacing: CGFloat = 10, alignment: HorizontalAlignment = .leading) {
        self.spacing = spacing
        self.runSpacing = runSpacing
        self.alignment = alignment
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // 计算布局所需的总大小
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            if currentLineWidth + size.width > maxWidth {
                // 换行
                totalHeight += currentLineHeight + runSpacing
                currentLineWidth = size.width
                currentLineHeight = size.height
            } else {
                // 继续当前行
                if index > 0 {
                    currentLineWidth += spacing
                }
                currentLineWidth += size.width
                currentLineHeight = max(currentLineHeight, size.height)
            }
        }

        // 添加最后一行的高度
        totalHeight += currentLineHeight

        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var y = bounds.minY
        var currentLineHeight: CGFloat = 0
        var currentLineSubviews: [LayoutSubviews.Element] = []
        var currentLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentLineWidth + size.width > maxWidth {
                // 换行，放置当前行的子视图
                placeLineSubviews(
                    in: bounds,
                    lineSubviews: currentLineSubviews,
                    lineWidth: currentLineWidth,
                    lineHeight: currentLineHeight,
                    y: y
                )
                y += currentLineHeight + runSpacing
                currentLineSubviews = []
                currentLineWidth = 0
                currentLineHeight = 0
            }

            // 添加子视图到当前行
            currentLineSubviews.append(subview)
            if currentLineSubviews.count > 1 {
                currentLineWidth += spacing
            }
            currentLineWidth += size.width
            currentLineHeight = max(currentLineHeight, size.height)
        }

        // 放置最后一行
        if !currentLineSubviews.isEmpty {
            placeLineSubviews(
                in: bounds,
                lineSubviews: currentLineSubviews,
                lineWidth: currentLineWidth,
                lineHeight: currentLineHeight,
                y: y
            )
        }
    }

    private func placeLineSubviews(
        in bounds: CGRect,
        lineSubviews: [LayoutSubviews.Element],
        lineWidth: CGFloat,
        lineHeight: CGFloat,
        y: CGFloat
    ) {
        let maxWidth = bounds.width
        var x = bounds.minX

        // 根据对齐方式调整起始位置
        switch alignment {
        case .leading:
            x = bounds.minX
        case .center:
            x = bounds.minX + (maxWidth - lineWidth) / 2
        case .trailing:
            x = bounds.minX + (maxWidth - lineWidth)
        default:
            x = bounds.minX
        }

        // 放置当前行的子视图
        for subview in lineSubviews {
            let size = subview.sizeThatFits(.unspecified)
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            x += size.width + spacing
        }
    }
}
