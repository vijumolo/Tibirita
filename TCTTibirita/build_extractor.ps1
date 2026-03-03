$mBytes = [System.IO.File]::ReadAllBytes("Diplomas\MARAVILLAS.pdf")
$eBytes = [System.IO.File]::ReadAllBytes("Diplomas\EXPLORADORES.pdf")
$mB64 = [Convert]::ToBase64String($mBytes)
$eB64 = [Convert]::ToBase64String($eBytes)

$html = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>PDF Extractor</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
</head>
<body>
  <h1>Extracting...</h1>
  <pre id="output"></pre>
  <script>
    pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

    const maravillasB64 = '$mB64';
    const exploradoresB64 = '$eB64';

    function base64ToUint8Array(base64) {
      const raw = window.atob(base64);
      const rawLength = raw.length;
      const array = new Uint8Array(new ArrayBuffer(rawLength));
      for(let i = 0; i < rawLength; i++) {
        array[i] = raw.charCodeAt(i);
      }
      return array;
    }

    async function extractFromPdfBytes(pdfBytes) {
      const pdfDocument = await pdfjsLib.getDocument({data: pdfBytes}).promise;
      const numPages = pdfDocument.numPages;
      const pagesData = [];
      
      for (let i = 1; i <= numPages; i++) {
        const page = await pdfDocument.getPage(i);
        const textContent = await page.getTextContent();
        const strings = textContent.items.map(item => item.str);
        const fullText = strings.join(' ');
        
        pagesData.push({
          page: i,
          containsMinusOne: fullText.includes('/-1'),
          text: fullText
        });
      }
      return pagesData;
    }

    async function extractAll() {
      const output = document.getElementById('output');
      try {
        const mBytes = base64ToUint8Array(maravillasB64);
        const eBytes = base64ToUint8Array(exploradoresB64);
        
        const mData = await extractFromPdfBytes(mBytes);
        const eData = await extractFromPdfBytes(eBytes);
        
        const result = JSON.stringify({
          maravillas: mData,
          exploradores: eData
        }, null, 2);
        
        output.textContent = result;
      } catch (e) {
        output.textContent = "Error: " + e.message + "\n" + e.stack;
      }
    }

    extractAll();
  </script>
</body>
</html>
"@

Set-Content -Path "extractor_inline.html" -Value $html
