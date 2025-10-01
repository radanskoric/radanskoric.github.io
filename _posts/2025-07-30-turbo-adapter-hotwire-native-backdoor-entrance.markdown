---
layout: post
title: "Turbo adapter: Hotwire Native's backdoor entrance"
date: 2025-07-25
categories: articles
tags: turbo adapter hotwire hotwire-native
mermaid: true
image: /assets/img/posts/hotwire-native-architecture.svg
---

Understanding exactly how Hotwire Native integrates with the web app can be very helpful both in debugging issues and deciding if Hotwire Native is the right choice in the first place. In particular, it's useful to understand how it takes over web navigation so it can make it feel native. This is exactly what this article explains.

First, a Haiku version:

> A native embrace, \
> The blossom of the web, \
> Joined by an adapter

Second, the TL;DR version: Hotwire Native injects a piece of JavaScript that integrates with the Turbo already present on the web and makes it talk to native mobile code.

Finally, the full explanation ...

## Hotwire Native is a wrapper around a mobile browser

In essence, a Hotwire Native app is a regular native app that uses a webview to render a web page inside the app. The webview embeds a mobile browser. Confusing? Here's a diagram:

![A Hotwire Native app architecture: webview inside the native app, with a browser inside that renders the webpage by talking to the server via HTTP.](/assets/img/posts/hotwire-native-architecture.svg)
*The browser inside the webview renders the webpage just like a regular browser would, fetching and submitting content over HTTP. As you'll learn, it also communicates with the native app wrapper to complete the illusion of a native app.*

On iOS, the browser runs inside the [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview){:target="_blank"} component from the [WebKit](https://developer.apple.com/documentation/webkit){:target="_blank"} UI framework. On Android, the browser runs inside a [WebView](https://developer.android.com/reference/android/webkit/WebView){:target="_blank"} component from the [Webkit](https://developer.android.com/jetpack/androidx/releases/webkit){:target="_blank"} Android library. Webviews are native components designed to embed a running browser inside a native app.

> Notice that only the web app is the one communicating with the server.
> This is the reason why you generally don't need a separate API for a Hotwire Native app.
> It piggy backs on web app's communication with the server.
{: .prompt-tip }

But Hotwire Native does more than just embed a web app. It enhances the app so that navigating it feels native. Out of the box, opening a new part of the web app slides a new screen on top of the existing one. Some screens open as modals. Although you're navigating a web app, Hotwire Native changes the navigation so that it feels like a native experience. So, how does it do that?

In short, it detects page navigation and inserts its own logic to change the rendering. The interesting part is how it detects page navigation.

### How it integrates with the Turbo running on the web

In theory, a WebView could detect when the browser navigates to a new page and react. However, with Turbo Drive, pages aren't actually navigated. Turbo Drive hijacks navigation and runs its own logic. Hotwire Native plugs itself into Turbo's navigation and tweaks it further.

This is the key "trick" for Hotwire Native's magic. Let's unpack it.

> Turbo has the concept of a [visit](https://turbo.hotwired.dev/handbook/drive#application-visits){:target="_blank"}. Think of it as page navigation that Turbo handles. I'll use the term **visit** from now on, as that's what Turbo calls it in the source code.
{: .prompt-info }

When Turbo processes a visit, it runs through the [`Session`](https://github.com/hotwired/turbo/blob/main/src/core/session.js){:target="_blank"} object (access it via `Turbo.session`). In the case of a **full page visit** (as opposed to a Turbo Frame visit), it goes through the instance of the [`Navigator`](https://github.com/hotwired/turbo/blob/main/src/core/drive/navigator.js){:target="_blank"} class. It's accessible globally through `Turbo.navigator`. The session object simply propagates the **visit** to the navigator's `proposeVisit` method:

```javascript
this.navigator.proposeVisit(expandURL(location), options)
```

The navigator checks if Turbo should handle the navigation. For example, it checks if the URL is in the same domain, i.e. if we're navigating within our app. If yes, it stops regular browser navigation and calls back to the `Session` object to perform a full page visit.

Session will in turn tell the **adapter** object to perform the visit:
```javascript
this.adapter.visitProposedToLocation(location, options)
```

More on the adapter in a moment. But first here’s the flow so far, explained as a diagram:

```mermaid
sequenceDiagram
    User->>Browser: click link
    Browser->>Turbo: capture<br/>click event
    Turbo->>Session: .visit
    Session->>Navigator: .proposeVisit
    note over Navigator: run checks: ok
    Navigator->>Session: .visitProposedToLocation
    Session->>Adapter: .visitProposedToLocation
```

Now, let's get back to the adapter. By default, Turbo uses the [`BrowserAdapter` class](https://github.com/hotwired/turbo/blob/main/src/core/native/browser_adapter.js){:target="_blank"}. This handles the low-level logic for executing a visit in the browser.

And this is exactly the place where Hotwire Native inserts itself!

You can swap out the adapter for your own by calling `Turbo.registerAdapter`. That’s exactly what Hotwire Native does: **it implements a TurboNative class and registers it as the adapter for Turbo**.

The JavaScript source is contained in a `turbo.js` source file that lives directly inside the native packages. The file is inserted directly into the running Webview instance. It constructs the `TurboNative` object, which it then registers as the new adapter.

An adapter is expected to implement several functions, but one stands out. Arguably the most important Turbo adapter function is `visitProposedToLocation`, which we see in the above diagram:
1. Turbo calls this whenever it's processing a visit.
2. The Hotwire Native adapter uses this to talk to the native code and decide: **let Turbo do its thing, or stop and let the native code load the URL?**

> If you’re having trouble with web/native integration, this is a great place to start your investigation.
>
> The full native adapter sources are in their respective Hotwire Native libraries:
> - For iOS: [Source/Turbo/WebView/turbo.js](https://github.com/hotwired/hotwire-native-ios/blob/main/Source/Turbo/WebView/turbo.js){:target="_blank"}
> - For Android: [core/src/main/assets/js/turbo.js](https://github.com/hotwired/hotwire-native-android/blob/main/core/src/main/assets/js/turbo.js){:target="_blank"}
{: .prompt-tip }

And this is it. Once it has prevented Turbo Drive from loading and taken over the loading of the page, it uses [path configuration](https://native.hotwired.dev/overview/path-configuration){:target="_blank"} to decide exactly how it will load the new page.

### In summary
- A Hotwire Native app embeds a WebView that runs a browser, which loads your mobile website.
- It injects custom JS that registers a Turbo adapter, replacing Turbo's default browser adapter.
- Turbo calls this adapter when performing a visit or other native-supported actions.
- The adapter communicates with the native code, letting it decide whether Turbo should do its usual thing or whether the native code will take over navigation.

> This article is extracted and adapted from my book ["Master Hotwire"](https://masterhotwire.com/){:target="_blank"}, _an e-book for experienced Rails developers to quickly get up to speed with Hotwire and Hotwire Native_.
{: .prompt-info }
