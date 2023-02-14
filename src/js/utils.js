async function loadTemplate(path) {
    const res = await fetch(path);
    const template = await res.text();
    return template;
  }
  
  export async function loadHeaderFooter() {
  
    let headerTemplate = await loadTemplate("../snippets/header.html");
    let footerTemplate = await loadTemplate("../snippets/footer.html");
    let navTemplate = await loadTemplate("../snippets/nav.html");
  
    const header = document.querySelector("header");
    const footer = document.querySelector("footer");
    const nav = document.querySelector("nav");
  
    renderWithTemplate(headerTemplate, header);
    renderWithTemplate(footerTemplate, footer);
    renderWithTemplate(navTemplate, nav);
  
  }