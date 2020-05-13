// import "./dist/style.css";
import './gen/tailwind-gen.css';
import './style.css';
const { Elm } = require("./src/Main.elm");
const pagesInit = require("elm-pages");

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
