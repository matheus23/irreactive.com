import './gen/tailwind-gen.css';
import './style.css';

const { Elm } = require("./src/Main.elm");
const CodeHighlighted = require("./src/Components/CodeHighlighted.elm");
const CodeInteractive = require("./src/Components/CodeInteractive.elm");
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

      const component = language == 'js interactive' ?
        CodeInteractive.Elm.Components.CodeInteractive :
        CodeHighlighted.Elm.Components.CodeHighlighted;

      this.innerHTML = '';
      this.appendChild(elmDiv);

      component.init({
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
