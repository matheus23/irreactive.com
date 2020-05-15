import './gen/tailwind-gen.css';
import './style.css';

const { Elm } = require("./src/Main.elm");
const Code = require("./src/Components/Code.elm");
const pagesInit = require("elm-pages");


customElements.define('custom-code',
  class extends HTMLElement {
    constructor() {
      super();
    }

    connectedCallback() {
      this.mountElm();
    }

    attributeChangedCallback() {
      this.mountElm();
    }

    static get observedAttributes() { return ['language']; }

    mountElm() {
      const codeText = this.textContent;
      const language = this.getAttribute('language');
      const elmDiv = document.createElement('div');
      this.innerHTML = '';
      this.appendChild(elmDiv);
      Code.Elm.Components.Code.init({
        node: elmDiv,
        flags: {
          language: language,
          code: codeText,
        },
      });
    }
  }
);

const app = pagesInit({
  mainElmModule: Elm.Main
});

const smoothScrollToPercentage = ({ domId, left, top }) => {
  const elem = document.getElementById(domId);
  if (elem != null) {
    elem.scrollTo({
      left: left != null ? left * elem.scrollWidth : undefined,
      top: top != null ? top * elem.scrollHeight : undefined,
      behavior: 'smooth'
    });
  }
}

app.then(elmApplication => {
  elmApplication.ports.smoothScrollToPercentagePort.subscribe(smoothScrollToPercentage);
  elmApplication.ports.scrollToBottom.subscribe(() => {
    // Wait one frame for Elm to render additional elements (that push the page down)
    window.requestAnimationFrame(() =>
      window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' })
    );
  });
});
