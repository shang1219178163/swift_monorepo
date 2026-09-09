//
//  NavigationBarModifier.swift
//  Navigator
//
//  自定义导航栏：标题 / leading / trailing / 前景与背景色；
//  title 为 nil 时可选回落 `NavigatorShort.titleProvider`。
//

import SwiftUI

#if os(iOS) || targetEnvironment(macCatalyst)

/// 导航栏修饰：隐藏系统返回键，支持自定义标题、leading 扩展与 trailing。
public struct NavigationBarModifier<TitleContent: View, LeadingExtra: View, Trailing: View>: ViewModifier {
    /// 显式标题；为 nil 时尝试 `NavigatorShort.titleProvider`
    public var title: String?
    /// 前景色（标题、返回箭头）
    public var titleColor: Color = .primary
    /// 导航栏背景色；nil 时用系统背景色
    public var backgroundColor: Color? = nil
    public var tint: Color? = nil
    public var displayMode: NavigationBarItem.TitleDisplayMode = .inline
    /// 根页等场景可隐藏返回
    public var hideBack: Bool = false
    /// 自定义返回；为 nil 时调用 `navigator.pop()`
    public var onBack: (() -> Void)?
    public var titleContent: TitleContent
    public var leadingExtra: LeadingExtra
    public var trailing: Trailing

    @EnvironmentObject private var navigator: Navigator
    @Environment(\.routeSettings) private var routeSettings

    private var barTint: Color { tint ?? titleColor }

    private var resolvedTitle: String {
        if let title { return title }
        guard let name = routeSettings?.name else { return "" }
        return NavigatorShort.titleProvider?(name) ?? name
    }

    private var hasCustomTitle: Bool { TitleContent.self != EmptyView.self }
    private var hasLeadingExtra: Bool { LeadingExtra.self != EmptyView.self }
    private var hasTrailing: Bool { Trailing.self != EmptyView.self }

    private var defaultBarBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #else
        Color.white
        #endif
    }

    public func body(content: Content) -> some View {
        content
            .navigationTitle(resolvedTitle)
            .navigationBarTitleDisplayMode(displayMode)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if !hideBack || hasLeadingExtra {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if !hideBack {
                            Button {
                                onBack?() ?? navigator.pop()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(titleColor)
                            }
                        }
                        leadingExtra
                    }
                }
                ToolbarItem(placement: .principal) {
                    if hasCustomTitle {
                        titleContent
                    } else {
                        Text(resolvedTitle)
                            .font(.headline)
                            .foregroundStyle(titleColor)
                            .lineLimit(1)
                    }
                }
                if hasTrailing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        trailing
                    }
                }
            }
            .tint(barTint)
            .toolbarBackground(backgroundColor ?? defaultBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    /// 统一导航栏样式；需环境中有 `Navigator`（`EnvironmentObject`）。
    /// - Parameter title: 为 nil 时回落 `NavigatorShort.titleProvider`（依赖 `\.routeSettings`）。
    public func navigationBarCustom<TitleContent: View, LeadingExtra: View, Trailing: View>(
        title: String? = nil,
        titleColor: Color = .primary,
        backgroundColor: Color? = nil,
        tint: Color? = nil,
        displayMode: NavigationBarItem.TitleDisplayMode = .inline,
        hideBack: Bool = false,
        onBack: (() -> Void)? = nil,
        @ViewBuilder titleContent: () -> TitleContent = { EmptyView() },
        @ViewBuilder leading: () -> LeadingExtra = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        modifier(NavigationBarModifier(
            title: title,
            titleColor: titleColor,
            backgroundColor: backgroundColor,
            tint: tint,
            displayMode: displayMode,
            hideBack: hideBack,
            onBack: onBack,
            titleContent: titleContent(),
            leadingExtra: leading(),
            trailing: trailing()
        ))
    }
}

#endif
