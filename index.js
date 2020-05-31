import './gen/tailwind-gen.css';
import './style.css';

const { Elm } = require("./src/Main.elm");
const CodeHighlighted = require("./src/Components/CodeHighlighted.elm");
const CodeInteractiveJs = require("./src/Components/CodeInteractiveJs.elm");
const CodeInteractiveElm = require("./src/Components/CodeInteractiveElm.elm");
const pagesInit = require("elm-pages");


function codeComponentByLanguage(language) {
  switch (language) {
    case 'js interactive': return CodeInteractiveJs.Elm.Components.CodeInteractiveJs;
    case 'elm interactive': return CodeInteractiveElm.Elm.Components.CodeInteractiveElm;
    default: return CodeHighlighted.Elm.Components.CodeHighlighted;
  }
}

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
      const codeText = this.customCode;
      const language = this.getAttribute('language');
      const elmDiv = document.createElement('div');

      const component = codeComponentByLanguage(language);

      this.innerHTML = '';
      this.appendChild(elmDiv);

      component.init({
        node: elmDiv,
        flags: {
          language: language,
          code: codeText || '',
        },
      });
    }
  }
);

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

pagesInit({ mainElmModule: Elm.Main }).then(app => {
  app.ports.smoothScrollToPercentagePort.subscribe(smoothScrollToPercentage);
  app.ports.scrollToBottom.subscribe(() => {
    // Wait one frame for Elm to render additional elements (that push the page down)
    window.requestAnimationFrame(() =>
      window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' })
    );
  });
});
