import * as ort from 'onnxruntime-web';

// Configuración de runtime ONNX sobre Wasm / WebGPU
ort.env.wasm.numThreads = Math.max(1, Math.floor(navigator.hardwareConcurrency / 2));
ort.env.wasm.wasmPaths = '/wasm/';

export class AIInferenceAdapter {
  private omrSession: ort.InferenceSession | null = null;
  private stemSession: ort.InferenceSession | null = null;

  async initOMRModel(modelPath: string = '/models/omr_model.onnx'): Promise<void> {
    try {
      this.omrSession = await ort.InferenceSession.create(modelPath, {
        executionProviders: ['webgpu', 'wasm'],
        graphOptimizationLevel: 'all',
      });
      console.log("ONNX Runtime inicializado con backend: WebGPU");
    } catch (err) {
      console.warn('Fallback a WASM Backend:', err);
      this.omrSession = await ort.InferenceSession.create(modelPath, {
        executionProviders: ['wasm'],
      });
      console.log("ONNX Runtime inicializado con backend: WASM");
    }
  }

  async initStemSeparationModel(modelPath: string = '/models/stem_separator.onnx'): Promise<void> {
    try {
      this.stemSession = await ort.InferenceSession.create(modelPath, {
        executionProviders: ['webgpu', 'wasm'],
        graphOptimizationLevel: 'all',
      });
      console.log("Stem Separation ONNX Runtime inicializado con backend: WebGPU");
    } catch (err) {
      console.warn('Fallback a WASM Backend para Stem Separation:', err);
      this.stemSession = await ort.InferenceSession.create(modelPath, {
        executionProviders: ['wasm'],
      });
      console.log("Stem Separation ONNX Runtime inicializado con backend: WASM");
    }
  }

  async runOMRInference(imageData: ImageData): Promise<Float32Array> {
    if (!this.omrSession) throw new Error('Modelo OMR no inicializado.');

    const tensor = this.imageToTensor(imageData);
    const feeds: Record<string, ort.Tensor> = { input_image: tensor };
    const results = await this.omrSession.run(feeds);

    return results.musicxml_logits.data as Float32Array;
  }

  private imageToTensor(imageData: ImageData): ort.Tensor {
    const { data, width, height } = imageData;
    const float32Data = new Float32Array(width * height);

    // Normalización de escala de grises [0, 1]
    for (let i = 0; i < data.length; i += 4) {
      float32Data[i / 4] = (data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114) / 255.0;
    }

    return new ort.Tensor('float32', float32Data, [1, 1, height, width]);
  }

  async runStemSeparation(audioBuffer: AudioBuffer): Promise<{ vocals: Float32Array; bass: Float32Array; drums: Float32Array; other: Float32Array; }> {
    if (!this.stemSession) throw new Error('Modelo de separación de Stems no inicializado.');

    const tensor = this.audioToTensor(audioBuffer);
    const feeds: Record<string, ort.Tensor> = { input_audio: tensor };
    const results = await this.stemSession.run(feeds);

    // Se asume que el modelo tiene salidas con estos nombres.
    return {
      vocals: results.vocals.data as Float32Array,
      bass: results.bass.data as Float32Array,
      drums: results.drums.data as Float32Array,
      other: results.other.data as Float32Array,
    };
  }

  private audioToTensor(audioBuffer: AudioBuffer): ort.Tensor {
    // NOTA: Esta es una simplificación. Una implementación real realizaría una
    // Transformada Rápida de Fourier de Tiempo Corto (STFT) para generar un espectrograma
    // complejo, que es el formato de entrada que suelen esperar los modelos de separación de audio.
    // La forma del tensor resultante dependería de los requisitos específicos del modelo
    // (p. ej., [canales, bins_de_frecuencia, frames_de_tiempo]).

    // Para este ejemplo, se usa el audio crudo de un canal.
    const audioData = audioBuffer.getChannelData(0);
    return new ort.Tensor('float32', audioData, [1, audioData.length]); // Forma: [batch_size, sequence_length]
  }
}