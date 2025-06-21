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

  // Ensure compiler directory exists
  if (!fs.existsSync(compilerDir)) {
    return res.status(500).json({ error: 'Compiler directory missing.' });
  }

  // Write DSL code to input.dsl
  try {
    fs.writeFileSync(inputDSLPath, dslCode);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to write input.dsl.' });
  }

  // Clean or create plots directory
  try {
    if (!fs.existsSync(plotsDir)) fs.mkdirSync(plotsDir);
    fs.readdirSync(plotsDir).forEach(f => fs.unlinkSync(path.join(plotsDir, f)));
  } catch (err) {
    return res.status(500).json({ error: 'Failed to prepare plots directory.' });
  }

  // Run your C-based compiler
  exec(`cd ${compilerDir} && ./compiler < input.dsl`, (err, stdout, stderr) => {
    if (err) {
      console.error('Compilation error:', stderr);
      return res.status(500).json({ error: 'DSL compilation failed.', details: stderr });
    }

    let generatedPython = '';
    try {
      generatedPython = fs.readFileSync(outputPythonPath, 'utf8');
    } catch (e) {
      generatedPython = '# Error: output.py not found.';
    }

    // Run the generated Python script
    exec(`cd ${compilerDir} && python3 output.py`, (err, stdout, stderr) => {
      const scriptOutput = err ? stderr : stdout;

      let plotFiles = [];
      try {
        plotFiles = fs.readdirSync(plotsDir)
          .filter(file => file.endsWith('.png'))
          .map(file => `/plots/${file}`);
      } catch (e) {
        console.error('Failed to list plot files:', e);
      }

      res.json({
        generated_python: generatedPython,
        console_output: scriptOutput.trim(),
        plots: plotFiles
      });
    });
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`🚀 DSL server running at http://localhost:${PORT}`);
});
