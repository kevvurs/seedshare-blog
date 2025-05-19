+++
title = "WebAssembly in Go"
date = 2025-05-18T11:00:00-06:00
description = "I return from my hiatus"
images = [ "/wasm1/gowasm.jpg" ]
tags = [ "development", "go", "wasm", "chat" ]
categories = [ "web", "ai" ]
+++

![go wasm](/wasm1/gowasm.jpg)

## Getting Started with WASM in GO

I have an itch I can't scratch. It started in college when I heard a
talk on [Web Assembly](wasm). I still cannot articulate the benefits
of this technology, and I feel like in the years that passed, it has
not exactly taken off. At least, not in the hockey stick growth seen byReact, Next, or Vue, which are each fascinating in their own right.
Still, something in the back of my mind keeps pulling me back towards
researching WASM.

![google trends](/wasm1/google-trends.png)
_hype train passing by WebAssembly (source: [Google Trends][trends])_

I asked [Claude][ai] to enumerate the benefits of WASM. Here's a few
that stuck out.
* Near-native performance - significantly Faster than JS for computationally intensive phases
* Portability - works across all major browsers
* No garbage collection

I cannot vouch for the veracity of these points, but I am willing to
find out more. For me, the selling point is the principle of a
polyglot World Wide Web. JS will always be the programming language of
the internet, but is there room for more?

## the pitch
In my effort to learn about WASM I plan to build a chatbot, micro-app.
My idea is to use WASM to build a Portable UI widget for chat, like
the kind you see proliferating across the internet now chats. My
long-term goal is to give it a standard API integration port such that
it can drop in to any website, and in the backend it will connect to
a lightweight proxy to leading LLM models.

I see the path for the backend to reuse the Vercel [aisdk][vercel]
spec. AI SDK provides a UI library for React, Vue, and Svelte.
Naturally, my chat module won't vendor any fancy framework. Instead, I
want to implement the AI SDK UI features internally, such that it can
fungibly interact with a backend designed for AI SDK to integrate with
[ChatGPT][sam], [grok][elon], or more. The product offering or value
prop will be for anyone standing up an AI SDK server for an LLM to
have a drop-in, product agnostic chat experience. And I will become a
WASM wizard in the process.

## a primer in WASM with Go
Crawl, Walk, Run. This was a mantra that I learned from my partner
when she worked on a UX Design team supporting [Microsoft Teams][msft]
early in its iteration. I have lofty goals for a full-time employed
SDE with some semblance of a social life. In this post, I will start
with a primer on using WASM with Go as a precursor of things to come.

I started with the hello world program on the official
[Go WASM page][wiki]. You can find my source on github in
[chatbox][repo].

```go {style=monokailight}
package main

import "fmt"

func main() {
	fmt.Println("Hello world")
}
```

To run this little program, I just compile it into a binary with
`GOOS=js GOARCH=wasm go build -o main.wasm`. Then, I serve it and an
[HTML file][html] locally. Go requires loading a
[driver script][driver], copied from my go installation, to setup WASM
on the page. The driver is 20kb and does not appear minified, so I
wonder if one must use this in Production.

Opening the page prints my message to the dev console. Now I am
officially a WASM engineer! Printing to console is not that exciting
though. Let's take things to the next level with a UI example. To help
with development, the Go wiki lists a few open source projects to
build UI in WASM. I tried one with the most Github stars and recent
commits, [go-app][app].

After a few failed experiments, I realized the framework is
full-stack. It doesn't run unless you also fire up an included server
runtime, not unlike [Next.js][next]. However, this is not good for me.
I want a client-side distributable binary file that renders and
handles the chatbox. The backend will be some LLM wrapper, not an
SSR engine

I scrapped my go-app diff and hit the road with pure Go for WASM.
First, I created the example in the `primer` directory to make
div elements and placeholder text on the page. I'm a nostalgic person,
so I added [Bootstrap v5][bs] CSS for quick styles directly in the
host HTML file. Now I can use `syscall/js` to get the DOM interface in
Go, and I can create elements to append to it. Voilla!

```go {style=monokailight}
package main

import (
	"fmt"
	"strconv"
	"syscall/js"
)

func main() {
	fmt.Println("Running WASM script...")

	// create the elements
	document := js.Global().Get("document")
	background := createDiv(document, "bg-secondary d-flex " +
	  "align-items-center justify-content-center vh-100")
	foreground := createDiv(document, "card bg-dark text-light p-4 " +
		"mx-4 my-auto rounded shadow-lg w3-card-4")
	title := createTitle(document, 1, "",
		`Welcome to WebAssembly UI!`)
	description := createParagraph(document, "",
	"This page was created using Go WASM. All the DOM elements are" +
	" generated with WASM and assembled into the DOM at runtime. A" +
	" driver script runs a .wasm binary file in the <head> tag to " +
	" execute the Go code responsible for this page.")
	code := createPre(document, "p-4 text-dark bg-light")
	code.Set("innerText",
		`document := js.Global().Get("document")
background := createDiv(document,
	"bg-dark d-flex align-items-center justify-content-center vh-100")
foreground := createDiv(document,
	"card bg-secondary text-light p-4 rounded shadow-lg, mx-4")
title := createTitle(document, 1, "",
	"Welcome to WebAssembly UI!"")
description := createText(document, "",
	"This page was created using Go WASM. All the DOM elements are
	generated with WASM and assembled into the DOM at runtime. A driver
	script runs a .wasm binary file in the <head> tag to execute the Go
	code responsible for this page."")`)
	link := createAnchor(document, "my-auto link-danger", "Learn more at seedshare.io",
		"https://seedshare.io/blog/wasm")

	// assemble the structure
	appendToDiv(foreground, title)
	appendToDiv(foreground, description)
	appendToDiv(foreground, code)
	appendToDiv(foreground, link)
	appendToDiv(background, foreground)

	// manipulate the dom
	document.Get("body").Call("appendChild", background)
	fmt.Println("Web = Assembled!")
}

func createElement(dom js.Value, tag, class string) js.Value {
	div := dom.Call("createElement", tag)
	div.Set("className", class)
	return div
}

func createDiv(dom js.Value, class string) js.Value {
	return createElement(dom, "div", class)
}

func createPre(dom js.Value, class string) js.Value {
	return createElement(dom, "pre", class)
}

func createText(dom js.Value, tag, class, content string) js.Value {
	element := createElement(dom, tag, class)
	element.Set("innerText", content)
	return element
}

func createTitle(dom js.Value, size int, class, content string) js.Value {
	return createText(dom, "h" + strconv.Itoa(size), class, content)
}

func createParagraph(dom js.Value, class, content string) js.Value {
	return createText(dom, "p", class, content)
}

func createAnchor(dom js.Value, class, content, url string) js.Value {
	element := createText(dom, "a", class, content)
	element.Set("href", url)
	return element
}

func appendToDiv(div, child js.Value) {
	div.Call("appendChild", child)
}
```

![primer](/wasm1/primer.png)
_HTML generated with WASM in Go_

The content and structure defined in the page is entirely defined in
Go. The result is an awkward Go-to-HTML program. Note, in researching
for this piece, I learned that WASM may not be an [optimal choice][y]
for DOM manipulation. It may be a better fit for a service worker that
does heavy tasks in the background. Still, this exercise is presented
for simple exposure to Go WASM.

## building a chat widget
Next, I created another Go module in the `chatbox` directory. This one
will render HTML for the floating chat widget. It will make a button
in the corner, and when clicked, it opens a window for chat. The
window has a minimize function, a title, a message stream, and a text
input box with a send button.

To avoid redundancy, I extracted the common [HTML functions][html-mod]
to a module that __primer__ and __chatbox__ can use.

```go {style=monokailight}
package html

import (
	"strconv"
	"syscall/js"
)

func CreateElement(dom js.Value, tag, class string) js.Value {
	div := dom.Call("createElement", tag)
	div.Set("className", class)
	return div
}

func CreateDiv(dom js.Value, class string) js.Value {
	return CreateElement(dom, "div", class)
}

func CreatePre(dom js.Value, class string) js.Value {
	return CreateElement(dom, "pre", class)
}

func CreateText(dom js.Value, tag, class, content string) js.Value {
	element := CreateElement(dom, tag, class)
	element.Set("innerText", content)
	return element
}

func CreateTitle(dom js.Value, size int, class, content string) js.Value {
	return CreateText(dom, "h" + strconv.Itoa(size), class, content)
}

func CreateParagraph(dom js.Value, class, content string) js.Value {
	return CreateText(dom, "p", class, content)
}

func CreateItalic(dom js.Value, class, content string) js.Value {
	return CreateText(dom, "i", class, content)
}

func CreateAnchor(dom js.Value, class, content, url string) js.Value {
	element := CreateText(dom, "a", class, content)
	element.Set("href", url)
	return element
}

func CreateButton(dom js.Value, class string) js.Value {
	element := CreateElement(dom, "button", class)
	element.Set("type", "button")
	return element
}

func CreateInput(dom js.Value, _type, class string) js.Value {
	element := CreateElement(dom, "input", class)
	element.Set("type", _type)
	return element
}

func CreateSpan(dom js.Value, class string) js.Value {
	element := CreateElement(dom, "span", class)
	return element
}

func CreateLine(dom js.Value, class string) js.Value {
	element := CreateElement(dom, "hr", class)
	return element
}

func Append(parent, child js.Value) {
	parent.Call("appendChild", child)
}
```

I ran `go get -u github.com/kevvurs/chatbox/html` to install the
common html package in the other modules, Now when I build __primer__, it also compiles code in the __html__ module for WASM.

```go {style=monokailight}
module github.com/kevvurs/chatbox/primer

go 1.24.2

require github.com/kevvurs/chatbox/html v0.0.0-20250507024745-b58d095a1b43 // indirect

replace github.com/kevvurs/chatbox/html => ../html
```
_installing shared html module and replacing source with the my local directory_

```go {style=monokailight}
import (
	"fmt"
	"syscall/js"

	"github.com/kevvurs/chatbox/html"
)
```
_importing html helper package in other modules_

The chatbox module will build a singular binary for my chat UI.
Since it is a widget, I will setup a build process with
[Make][mk] to compile and copy the __primer__ and __chatbox__ binaries
to an output directory and add an HTML file to load both. __Primer__
will be the demo page for testing the widget, but I can publish the
__chatbox__ binary independently to CDN. Let's make a simple chat window.

```go {style=monokailight}
func main() {
	fmt.Println("Loading chatbox v1.0")
	document := js.Global().Get("document")

	// create a floating window for chat
	chatWindow := html.CreateDiv(document, "fixed-bottom chatwindow")

	menubar := html.CreateDiv(document, "d-flex justify-content-between " +
		"align-items-center bg-light p-1")
	chatTitle := html.CreateTitle(document, 5, "mb-0", "Chatbox")
	dismissButton := html.CreateButton(document, "btn bg-transparent" +
		"btn-sm border-0")
	dismissIcon := html.CreateItalic(document, "bi bi-x-lg", "")
	html.Append(menubar, chatTitle)
	html.Append(dismissButton, dismissIcon)
	html.Append(menubar, dismissButton)

	chat := html.CreateDiv(document, "bg-light p-1 border " +
		"border-start-0 border-end-0 chatstream")

	sendbar := html.CreateDiv(document, "input-group bg-light px-1 py-2")
	textEntry := html.CreateInput(document, "text", "form-control bg-light " +
		"border-1 border-secondary focus-ring focus-ring-secondary")
	textEntry.Set("placeholder", "Aa")
	sendChatButton := html.CreateButton(document, "btn btn-outline-secondary")
	sendIcon := html.CreateItalic(document, "bi bi-send", "")
	html.Append(sendbar, textEntry)
	html.Append(sendChatButton, sendIcon)
	html.Append(sendbar, sendChatButton)
	
	html.Append(chatWindow, menubar)
	html.Append(chatWindow, chat)
	html.Append(chatWindow, sendbar)

	// TODO: initialize click handlers
	
	document.Get("body").Call("appendChild", chatWindow)
	fmt.Println("chatbox loaded")
}
```

This is enough to give us a view with a floating chat window. It has
a button to close the window and a basic text input with a send
button. In a minute, we'll add click listeners. But first, I need a
moment to make a build system to compile __chatbox__ and __primer__
modules. I'll copy their binaries to a `dist` directory.

```makefile {style=monokailight}
build:
	GOOS=js GOARCH=wasm go build -o main.wasm
```
_individual Go module Makefile_

```makefile {style=monokailight}
build-primer:
	$(MAKE) -C primer build

build-chatbox:
	$(MAKE) -C chatbox build

build: build-primer build-chatbox
	mkdir -p dist/
	mv primer/main.wasm dist/main.wasm
	mv chatbox/chat.wasm dist/chat.wasm
	cp primer/wasm_exec.js dist/wasm_exec.js
	cp index.html dist/index.html
```
_project Makefile assembles the modules for the page and widget, and
then copies binaries and supporting files to `dist`_

I use Make to compile each module into WASM. I added a Makefile in the
project root to iteratively build the modules with make and move
resources to dist.

I also needed to add some custom style tweaks for the window sizing
and breakpoints.

```html {style=monokailight}
    <style>
      /* Chatbox.css  */
      .openchat {
        left: 24px;
        bottom: 24px;
      }

      .chatwindow {
        max-width: 285px;
        height: 415px;
        left: 24px;
        bottom: 24px;
      }

      .chatstream {
        height: 315px;
      }

      .mw-75 {
        max-width: 75% /* IDK why this is broken in bootstrap*/
      }

      @media (min-width: 768px) {
        .chatwindow {
          max-width: 335px;
        }
      }

      @media (min-width: 1200px) {
        .chatwindow {
          max-width: 415px;
        }
      }
    </style>
```

Now it's time for the fundamentals. My chat input should take text and
push it to the stream of messages as a bubble. This will happen when
the user clicks send or presses enter. There is some layout work
needed to make the messages look natural, following the patterns of
iMessage and Facebook messenger. Additionally, the user can dismiss
the chat and click a floating icon to resume it. This will implement
basic chat box components.

```go {style=monokailight}
var document js.Value;
var container js.Value;
var chatWindow js.Value;
var chat js.Value;
var textEntry js.Value;

func main() {
	fmt.Println("Loading chatbox v1.0")

	// create a floating icon to open the chat when idle
	document = js.Global().Get("document")
	container = html.CreateDiv(document, "fixed-bottom openchat collapse show")
	openChatButton := html.CreateButton(document, "btn btn-light btn-lg btn-circle p-2")
	icon := html.CreateItalic(document, "bi bi-chat-fill", "")

	html.Append(openChatButton, icon)
	html.Append(container, openChatButton)

	// create a floating window for chat
    // ...omitted for brevity...

	// initialize click handlers
	textEntry.Call("addEventListener", "keydown", js.FuncOf(sendChatOnEnter))
	sendChatButton.Call("addEventListener", "click", js.FuncOf(sendChat))
	openChatButton.Call("addEventListener", "click", js.FuncOf(openChat))
	dismissButton.Call("addEventListener", "click", js.FuncOf(dismissChat))

	document.Get("body").Call("appendChild", chatWindow)
	document.Get("body").Call("appendChild", container)
	fmt.Println("chatbox loaded")
	<-make(chan bool)  // required to receives events from JS
}

func sendChat(this js.Value, args []js.Value) any {
	message := textEntry.Get("value").String()
	if strings.TrimSpace(message) == "" {
		return ""
	}
	messageBubble := html.CreateParagraph(document, "bg-primary p-1 mw-75 align-self-end " +
		"flex-shrink-0 text-light rounded shadow-lg",	message)
	html.Append(chat, messageBubble)
	chat.Set("scrollTop", chat.Get("scrollHeight"))
	textEntry.Set("value", "")
	return ""
}

func sendChatOnEnter(this js.Value, args []js.Value) any {
	if len(args) > 0 && args[0].Get("key").String() != "Enter" {
		return ""
	}
	return sendChat(this, args)
}


func openChat(this js.Value, args []js.Value) any {
  openClassList := container.Get("classList")
	openClassList.Call("remove", "show")
	chatClassList := chatWindow.Get("classList")
	chatClassList.Call("add", "show")
	return ""
}


func dismissChat(this js.Value, args []js.Value) any {
	classList := chatWindow.Get("classList")
	classList.Call("remove", "show")
	openClassList := container.Get("classList")
	openClassList.Call("add", "show")
	return ""
}
```
_chatbox interactivity implementation_

![demo](/wasm1/chatdemo.png)

### [see a demo of the project here](/wasm1/demo/)

And that's it! I have a portable UI module for chat. It's built in Web
Assembly with Go. The WASM file can be shipped independently to any
site! I did use bootstrap for syling in this experiment. Plus
customers need to load the driver script provided by, Go.
In a serious project these dependencies would need to be reduced in
size and vendored into the distributable asset. However, for the sake
of this project, it's perfect.

## what I learned

GO WASM was easier than I thought! The programming language added
surprisingly less friction than expected. The access to DOM API was
simple to use. I was impressed by the ease of interoperating with the
JS stack through pure go functions in click listeners. The build
process was fast for my little program, and I was delighted that it
worked with modules that exposed helpers for WASM operations. I could
see this scale to large projects Where Go modules break down core
components. Building this simple app taught me a lot about using WASM,
scratching an itch. In a future post, I hope to revisit this project
to integrate it with an LLM to respond to messages.

## a disclaimer
In this post, I used WASM to use JS to create DOM elements to learn
more about the technology. This may not represent an ideal use case
for it. Some would argue that WASM is inefficient at making DOM
updates, and that it is suitable for computationally complex work in
a service worker thread. For example, using it to process OpenGL
graphics or optimization algorithms. But at some scale, much of this
processing can be done in the backend by servers. For this reason, the
best space to apply WASM might be for complex client processing. The
filesize for the WASM output is hard to justify for making few HTML
elements, but this post provides an approachable look at the basics
for Go & WebAssembly.

[wasm]: https://webassembly.org/
[trends]: https://trends.google.com/trends/explore?date=2015-04-18%202025-05-18&geo=US&q=%2Fg%2F11c3kj4zzq,%2Fm%2F012l1vxv,%2Fg%2F11c0vmgx5d&hl=en
[ai]: https://claude.ai/
[vercel]: https://ai-sdk.dev/
[sam]: https://chatgpt.com/
[elon]: https://x.ai/
[msft]: https://news.microsoft.com/announcement/teams-platform-introduced/
[wiki]: https://go.dev/wiki/WebAssembly
[repo]: https://github.com/kevvurs/chatbox
[html]: https://github.com/kevvurs/chatbox/blob/c5ccd4270f16dd94252aaf5f2f7d4347cac5e435/primer/index.html
[driver]: https://github.com/kevvurs/chatbox/blob/c5ccd4270f16dd94252aaf5f2f7d4347cac5e435/primer/wasm_exec.js
[app]: https://go-app.dev/
[next]: https://nextjs.org/
[bs]: https://getbootstrap.com/docs/5.0/getting-started/introduction/
[y]: https://news.ycombinator.com/item?id=36121613
[html-mod]: https://github.com/kevvurs/chatbox/tree/main/html
[mk]: https://www.gnu.org/software/make/manual/make.html
