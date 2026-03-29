document.addEventListener("DOMContentLoaded", function () {
  var current = window.location.pathname.split("/").pop();
  document.querySelectorAll(".moover-chapter-nav a[data-moover-chapter]").forEach(function (link) {
    if (link.getAttribute("data-moover-chapter") === current) {
      link.classList.add("is-active");
      link.setAttribute("aria-current", "page");
    }
  });
});
