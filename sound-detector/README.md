# Sound Detector

Live recording the microphone with [pyaudio](https://people.csail.mit.edu/hubert/pyaudio/)
feeding it to a TensorFlow YAMNet retrained model.

I used transfer learning on the [YAMNet model](https://tfhub.dev/google/yamnet/1) that
has been trained on the [AudioSet data](https://research.google.com/audioset/) to narrow
it down to my particular case of high heel detection.

- [Transfer learning with YAMNet for environmental sound classification](https://www.tensorflow.org/tutorials/audio/transfer_learning_audio)
- [Build your own real-time voice command recognition model with TensorFlow](https://www.youtube.com/watch?v=m-JzldXm9bQ)
- [Realtime Voice Command Recognition](https://github.com/AssemblyAI-Examples/realtime-voice-command-recognition)
- [Simple Audio Recognition on a Raspberry Pi using Machine Learning (I2S, TensorFlow Lite)](https://electronut.in/audio-recongnition-ml/)

To run the Jupyter Notebook you will need the pip `notebook` package installed, then:

```
jupyter notebook transfer_learning.ipynb
```

## Dependencies

This Python project uses the [poetry](https://python-poetry.org/) packaging and
dependency management tool.

In my case my LSP of my editor won't pick up the dependencies because `poetry`
encapsulates them.

You can either run a `poetry shell` and open the text editor or install them with pip
on your python installation (`pyenv` in my case):

```
pyenv install 3.11.5
pyenv global 3.11.5
pyenv virtualenv my_env_for_this_project
pyenv global my_env_for_this_project

poetry export --format=requirements.txt > requirements.txt
pip install -r requirements.txt

nvim
```

## Adapting

- [ ] Record some high-heel samples with the same specs the model was trained with.
- [ ] Run the transference learning and check its results.
- [ ] Save out the model.
- [ ] Prepare the live microphone inference to feed 1-2 second samples to the model.
- [ ] React on matches to the high-heel sound.
