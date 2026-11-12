/* ==========================================================================
   zsh-ghost-ai — Navigation: sticky nav, mobile toggle, smooth scroll
   ========================================================================== */

const nav = document.getElementById("nav");
const navLinks = document.getElementById("nav-links");
const navToggle = document.getElementById("nav-toggle");

/* Sticky nav background on scroll */
let ticking = false;
function onScroll() {
  if (!ticking) {
    window.requestAnimationFrame(() => {
      if (window.scrollY > 40) {
        nav.classList.add("scrolled");
      } else {
        nav.classList.remove("scrolled");
      }
      ticking = false;
    });
    ticking = true;
  }
}
window.addEventListener("scroll", onScroll, { passive: true });

/* Mobile menu toggle */
if (navToggle && navLinks) {
  navToggle.addEventListener("click", () => {
    const isOpen = navLinks.classList.toggle("open");
    navToggle.setAttribute("aria-expanded", isOpen);
  });

  /* Close menu when a link is clicked */
  navLinks.querySelectorAll("a").forEach((a) => {
    a.addEventListener("click", () => {
      navLinks.classList.remove("open");
      navToggle.setAttribute("aria-expanded", "false");
    });
  });
}

/* Smooth scroll to anchor links */
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener("click", (e) => {
    const href = anchor.getAttribute("href");
    if (href && href.length > 1 && document.querySelector(href)) {
      e.preventDefault();
      document.querySelector(href).scrollIntoView({ behavior: "smooth" });
    }
  });
});

/* Highlight active nav link on scroll */
const sections = document.querySelectorAll("section[id]");
const navAnchors = document.querySelectorAll(".nav-links a[href^='#']");

function highlightActive() {
  const scrollPos = window.scrollY + 120;
  let current = sections[0];
  sections.forEach((section) => {
    if (section.offsetTop <= scrollPos) current = section;
  });
  navAnchors.forEach((a) => {
    a.classList.toggle("active", a.getAttribute("href") === `#${current.id}`);
  });
}
window.addEventListener("scroll", highlightActive, { passive: true });
window.addEventListener("load", highlightActive);
