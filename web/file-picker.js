window.filePickerBridge = {
  pickFile: function() {
    return new Promise((resolve, reject) => {
      try {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/*';
        input.style.display = 'none';

        input.onchange = async (e) => {
          try {
            const file = e.target.files?.[0];
            if (!file) {
              resolve(null);
              return;
            }

            const reader = new FileReader();
            reader.onload = (event) => {
              try {
                const bytes = new Uint8Array(event.target.result);
                resolve({
                  name: file.name,
                  bytes: Array.from(bytes)
                });
              } catch (err) {
                reject(err);
              }
            };
            reader.onerror = () => reject(reader.error);
            reader.readAsArrayBuffer(file);
          } catch (err) {
            reject(err);
          }
        };

        input.onerror = () => reject(new Error('Error selecting file'));
        document.body.appendChild(input);
        input.click();
        document.body.removeChild(input);
      } catch (err) {
        reject(err);
      }
    });
  }
};
