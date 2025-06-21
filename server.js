const express = require('express');
const app = express();
const path = require('path');
const { exec } = require('child_process');
const fs = require('fs');

const PORT = process.env.PORT || 3000;
const compilerDir = path.join(__dirname, 'compiler');
const inputDSLPath = path.join(compilerDir, 'input.dsl');
const outputPythonPath = path.join(compilerDir, 'output.py');
const plotsDir = path.join(compilerDir, 'plots');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/plots', express.static(plotsDir));

app.post('/compile', (req, res) => {
  const dslCode = req.body.code;
  fs.writeFileSync(inputDSLPath, dslCode);

  try {
    if (!fs.existsSync(plotsDir)) fs.mkdirSync(plotsDir);
    fs.readdirSync(plotsDir).forEach(file =>
      fs.unlinkSync(path.join(plotsDir, file))
    );
  } catch (err) {
    console.error("Failed to clean plots folder.");
  }

  exec(`cd ${compilerDir} && ./dsl_compiler input.dsl`, (err, stdout, stderr) => {
    if (err) return res.status(500).json({ error: stderr });

    let pythonCode = fs.existsSync(outputPythonPath)
      ? fs.readFileSync(outputPythonPath, 'utf8')
      : "# output.py not found";

    exec(`cd ${compilerDir} && python3 output.py`, (pyErr, pyOut, pyStderr) => {
      const finalOutput = pyErr ? pyStderr : pyOut;
      const plots = fs.readdirSync(plotsDir)
        .filter(f => f.endsWith('.png'))
        .map(f => `/plots/${f}`);

      res.json({
        generated_python: pythonCode,
        console_output: finalOutput.trim(),
        plots: plots
      });
    });
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
