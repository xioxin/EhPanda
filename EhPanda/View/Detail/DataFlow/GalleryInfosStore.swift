//
//  GalleryInfosStore.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 4/01/23.
//

import TTProgressHUD
import ComposableArchitecture

struct GalleryInfosState: Equatable {
    enum Route {
        case hud
    }

    @BindingState var route: Route?
    var hudConfig: TTProgressHUDConfig = .copiedToClipboardSucceeded
}

enum GalleryInfosAction: BindableAction {
    case binding(BindingAction<GalleryInfosState>)
    case copyText(String)
}

struct GalleryInfosEnvironment {
    let hapticsClient: HapticsClient
    let clipboardClient: ClipboardClient
}

let galleryInfosReducer = Reducer<GalleryInfosState, GalleryInfosAction, GalleryInfosEnvironment>
{ state, action, environment in
    switch action {
    case .binding:
        return .none

    case .copyText(let text):
        state.route = .hud
        return .merge(
            environment.clipboardClient.saveText(text).fireAndForget(),
            environment.hapticsClient.generateNotificationFeedback(.success).fireAndForget()
        )
    }
}
.binding()
