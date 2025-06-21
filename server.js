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

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/plots', express.static(plotsDir));

// POST endpoint for DSL compilation
app.post('/compile', (req, res) => {
  const dslCode = req.body.code;
  if (!dslCode || typeof dslCode !== 'string') {
    return res.status(400).json({ error: 'Invalid DSL code input.' });
  }

  // Save input.dsl
  try {
    fs.writeFileSync(inputDSLPath, dslCode);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to write input.dsl.' });
  }

  // Clean/create plots directory
  try {
    if (!fs.existsSync(plotsDir)) fs.mkdirSync(plotsDir);
    fs.readdirSync(plotsDir).forEach(f => fs.unlinkSync(path.join(plotsDir, f)));
  } catch (err) {
    return res.status(500).json({ error: 'Failed to clean plots directory.' });
  }

  // Run DSL compiler
  exec(`cd ${compilerDir} && ./dsl_compiler input.dsl`, (err, stdout, stderr) => {
    if (err) {
      console.error('❌ Compiler Error:', stderr);
      return res.status(500).json({ error: 'Compiler failed', details: stderr });
    }

    let pythonCode = '';
    try {
      pythonCode = fs.readFileSync(outputPythonPath, 'utf8');
    } catch {
      pythonCode = '# output.py not found.';
    }

    // Run Python code
    exec(`cd ${compilerDir} && python3 output.py`, (pyErr, pyOut, pyStderr) => {
      const consoleOutput = pyErr ? pyStderr : pyOut;

      let plotImages = [];
      try {
        plotImages = fs.readdirSync(plotsDir)
          .filter(f => f.endsWith('.png'))
          .map(f => `/plots/${f}`);
      } catch (e) {
        console.error('⚠️ Plot read error:', e);
      }

      res.json({
        generated_python: pythonCode,
        console_output: consoleOutput.trim(),
        plots: plotImages
      });
    });
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
