function compileDSL() {
  const dslCode = document.getElementById("dslInput").value;

  fetch("/compile", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ code: dslCode })
  })
    .then(res => res.json())
    .then(data => {
      document.getElementById("pythonOutput").value = data.generated_python || "// No code generated.";

      const output = data.console_output || "No output.";
      const formattedOutput = output
        .split('\n')
        .map(line => line.trim())
        .filter(line => line.length)
        .map(line => `• ${line}`)
        .join('\n');
      document.getElementById("consoleOutput").textContent = formattedOutput;

      const plotContainer = document.getElementById("plotImages");
      plotContainer.innerHTML = "";

      if (data.plots && data.plots.length) {
        data.plots.forEach(src => {
          const img = document.createElement("img");
          img.src = src;
          img.alt = "Plot";
          img.classList.add("plot-img");
          plotContainer.appendChild(img);
        });
      } else {
        plotContainer.textContent = "📊 No plots generated.";
      }
    })
    .catch(err => {
      document.getElementById("consoleOutput").textContent = "Compilation failed: " + err.message;
    });
}

function toggleTheme() {
  document.body.classList.toggle("dark-mode");
}
