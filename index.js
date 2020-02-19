import "./dist/style.css";
const { Elm } = require("./src/Main.elm");
const pagesInit = require("elm-pages");

// const template = document.createElement("template");
// template.innerHTML = `
//   <style>
//     :host {
//       display: block;
//     }

//     .carusel {
//       display: flex;
//       flex-direction: row;
//       max-width: 100%;
//       overflow-x: scroll;
//       scroll-snap-type: x mandatory;
//       align-items: center;


//       -ms-overflow-style: none; /* Internet Explorer 10+ */
//       scrollbar-width: none; /* Firefox */
//     }

//     .carusel::-webkit-scrollbar {
//         display: none; /* Safari and Chrome */
//     }

//     ::slotted(*) {
//       min-width: 100%;
//       margin: auto 0;
//       scroll-snap-align: start;
//     }

//   </style>
//   <div class="carusel"><slot></slot></div>
//   <div class="dots-div"></div>
//   `.trim();

// window.customElements.define("custom-carusel", class extends HTMLElement {
//   constructor() {
//     super();

//     this.addEventListener("scroll", ev => this.handleScroll(ev));

//     this.attachShadow({ mode: "open" });
//     this.shadowRoot.appendChild(template.content.cloneNode(true));
//   }

//   connectedCallback() {
//     this.numChildren = this.children.length;
//     const dotsDiv = this.shadowRoot.querySelector("div.dots-div");
//     dotsDiv.innerText = this.numChildren;

//   }

//   handleScroll(ev) {
//   }

// });

pagesInit({
  mainElmModule: Elm.Main
});
