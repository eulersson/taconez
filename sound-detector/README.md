# Sound Detector

Identifies a specific sound and notifies the
[Sound Distributor](/docs/sound-distributor).

See the [Architecture](/#architecture) section on the root [README.md](/) for more.

I recommend having a look at the general documents first:

- [General Development Workflow](/docs/4-development-workflow.md)
- [Docker Container Sound](/docs/3-docker-container-sound.md)

## Build & Run

Build:

```
anesowa@rpi-master:~/anesowa $ docker build -t anesowa/sound-detector:1.0.0 ./sound-detector
```

Run:

```
anesowa@rpi-master:~/anesowa $ docker run --rm -it \
  --add-host host.docker.internal:host-gateway \
  -e PULSE_SERVER host.docker.internal \
  -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
  anesowa/sound-detector:1.0.0
```

## Deploy

- [Provisioning & Deployment](/docs/1-provisioning-and-deployment.md)

## Development Workflow

You can choose to either develop using a container or not. It's easier to develop using
a container (running the IDE from the host), you can still have LSP features like
autocompletion and suggestions! But I realized some of them do not work, like jumping to
a python library file that's outside the project: if you jump to the definition of a
third-party import the local Neovim will try to open a file that exists on the container
and not the host.

So you are free to choose:

| Method                                                                              | Advantages                                                                   | Disadvantages                                                                                                                                                                                               |
| ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Local Development](#local-development)                                             | Full LSP features, including "Go to definition" on third party libraries     | You have to install some system dependencies: `pyenv`, `poetry`, `portaudio`, ...                                                                                                                           |
| [Container Development (IDE from Host)](#container-development-running-ide-in-host) | System project dependencies are solved by the container build's instructions | You neeed to configure the IDE to run the container's LSP servers instead of the host's and some features like "Go to definition" on third-party libs don't work because the host doesn't have those files. |

### Local Development

If it's not the case use **pyenv** to install the right version.

Follow the
[official installation instructions](https://github.com/pyenv/pyenv#installation):

```
curl https://pyenv.run | bash

# Then add the following in the ~/.bashrc
#
#   export PYENV_ROOT="$HOME/.pyenv"
#   [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#   eval "$(pyenv init -)"
#   eval "$(pyenv virtualenv-init -)"
#
```

Then you can install and set the correct Python version:

```
# If on the Raspberry Pi install development OpenSSL libraries before building Python
#
#   https://github.com/pyenv/pyenv/wiki/Common-build-problems#error-the-python-ssl-extension-was-not-compiled-missing-the-openssl-lib
#
sudo apt install libssl-dev

pyenv install 3.11.5
```

Now activate the installation:

```
# Remember to revert to the system-installed Python afterwards `pyenv global system`.
pyenv global 3.11.5
```

Install the system libraries that will be needed for building the python packages:

```
sudo apt install portaudio19-dev
```

Then you can proceed to install poetry, the package management tool that is more aware
of the dependency resolution. Follow the
[official instructions](https://python-poetry.org/docs/#installation):

```
# On macOS / Linux:
pip install


# On Raspberry:
pip install --upgrade pip \
 && pip install --upgrade keyrings.alt \ # TODO: Needed?
 && pip install poetry \
 && poetry config virtualenvs.create false \
 && poetry install --no-interaction
```

**NOTE**: This will install only tflite-runtime and will not install the tensorflow core
packages. If you want to install core packages (for development) then pass the
dependency group on the CLI command `poetry install --with tensorflow-dev` (see
`pyproject.toml`) to see the `tensorflow-dev` group.

Now to install the dependencies on Raspberry Pi:

```
# Avoid hanging by disabling the keyring backend.
#
#   https://stackoverflow.com/a/60804443
#
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
poetry install # Choose whether you want tensorflow core packages with `--with tensorflow-dev`.
```

Python projects such as the `sound-detector` use the
[poetry](https://python-poetry.org/) packaging and dependency management tool.

In my case my LSP of my editor won't pick up the dependencies because `poetry`
encapsulates them.

You can either run a `poetry shell` and open the text editor or install them with pip on
your python installation (`pyenv` in my case). You can also run a Python console with
`poetry run python`.

First make sure Python is compliant with the python version specified in
`pyproject.toml`:

```
[tool.poetry.dependencies]
python = "^3.11,<3.12"
```

The `sound-detector` Python project uses `poetry` to handle dependencies. To develop on
your local machine:

```
# Install dependencies. Poetry will place them on a virtual environment.
eulersson@macbook:~/Devel/anesowa $ poetry install

# See where the virtual environment is installed.
eulersson@macbook:~/Devel/anesowa $ poetry env info

Virtualenv
Python:         3.10.13
Implementation: CPython
Path:           /Users/eulersson/Library/Caches/pypoetry/virtualenvs/sound-detector-CXfsoo8U-py3.10
Executable:     /Users/eulersson/Library/Caches/pypoetry/virtualenvs/sound-detector-CXfsoo8U-py3.10/bin/python
Valid:          True

System
Platform:   darwin
OS:         posix
Python:     3.10.13
Path:       /Users/eulersson/.pyenv/versions/3.10.13
Executable: /Users/eulersson/.pyenv/versions/3.10.13/bin/python3.10
```

Now that you know the virtual env lives in
`/Users/eulersson/Library/Caches/pypoetry/virtualenvs/sound-detector-CXfsoo8U-py3.10`
add a `pyrightconfig.json` on the root of the Python project
`~/Devel/anesowa/sound-detector/pyrightconfig.json`:

```
{
   "venv" : "sound-detector-oq1WgInS-py3.11",
   "venvPath" : "/Users/ramon/Library/Caches/pypoetry/virtualenvs"
}
```

This will help `pyright` LSP to be able to understand and resolve the project.

### Container Development (Running IDE in Host)

Thanks to this
[reddit comment](https://www.reddit.com/r/neovim/comments/y1hryr/comment/iry6c0q/) we
see it's possible to run a language server within our app's container and tell our IDE
to connect to it.

First build the container:

```
eulersson@macbook:~/Devel/anesowa $ docker build \
  --build-arg="DEBUG=1" \
  --build-arg="INSTALL_DEV_DEPS=1" \
  --build-arg="USE_TFLITE=0" \
  -t anesowa/sound-detector:1.0.0 \
  ./sound-detector
```

To run an app container:

```
eulersson@macbook:~/Devel/anesowa $ docker run \
  --rm -it \
  --add-host host.docker.internal:host-gateway \
  -e PULSE_SERVER host.docker.internal \
  -v $HOME/.config/pulse/cookie:/root/.config/pulse/cookie \
  --name anesowa-sound-detector-app-container \
  anesowa/sound-detector:1.0.0
```

Then run a container LSP server:

```
eulersson@macbook:~/Devel/anesowa $ docker run -it \
  -v $(pwd):/anesowa/sound-detector \
  --add-host dev-hack:127.0.0.1 \
  --net host \
  --hostname dev-hack \
  --entrypoint /bin/bash \
  --init \
  --detach \
  --name anesowa-sound-detector-pyright-dev-container \
  anesowa/sound-detector:1.0.0-dev
```

When you are done you working remember to stop and delete the container:

```
eulersson@macbook:~ $ docker stop --time 0 anesowa-sound-detector-pyright-dev-container
eulersson@macbook:~ $ docker rm anesowa-sound-detector-pyright-dev-container
```

Now depending on your IDE the steps will differ, but basically you need to configure the
pyright language server command to be the one from the container using `docker exec`:

#### LunarVim / NeoVim

If using LunarVim open up `~/.config/lvim/config.lua` and add these lines:

```lua
require("lvim.lsp.manager").setup("pyright", {
  -- TODO: I still haven't figured out yet is how to switch the cmd out on a per project
  -- basis. I'd like to only use this weird pyright setup in my main dev project, but
  -- then use regular (Mason installed) pyright outside of docker in general.
  cmd = {
    "docker",
    "exec",
    "-i",
    "anesowa-sound-detector-pyright-dev-container",
    "pyright-langserver",
    "--stdio",
  },
  single_file_support = true,
  settings = {
    pyright = {
      disableLanguageServices = false,
      disableOrganizeImports = false
    },
    python = {
      analysis = {
        autoImportCompletions = true,
        autoSearchPaths = true,
        diagnosticMode = "workspace", -- openFilesOnly, workspace
        typeCheckingMode = "basic",   -- off, basic, strict
        useLibraryCodeForTypes = true
      }
    }
  },
  before_init = function(params)
    -- LSP spec has a default flag that will cause you some trouble; if an LSP server
    -- can't find its parent's processId, it will shut itself down after a second or so.
    -- You need to tell it to ignore the processId shutdown behaviour (or start your
    -- docker container to share the process space with your host).
    params.processId = vim.NIL
  end,
})
```

**TODO**: Chose the pyright container execution on a per-project basis, and if not
defined then use the regular way by using the one installed by the Mason in LunarVim.

If using NeoVim open up your lua file, e.g. `~/.config/nvim/init.lua` and add:

```
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {
  ... <PUT HERE THE { cmd {...}, settings {...}, python {...} ... } AFOREMENTIONED> ...
}
```

### Container Development (Running IDE in Container)

Try to see what the workflow is like to run Neovim in the container instead of running
it from outside.

Considerations:

- Installing LunarVim first.
- Binding LunarVim configs.
- Have a persistent volume where LunarVim stuff gets downloaded to.
- Checking the RAM consumed by the container.

TBD.

### Microphone & Speaker

Read the guide on [Docker Container Sound](/docs/3-docker-container-sound.md) to make
sure you have PulseAudio installed on your host machine with the
`module-native-protocol-tcp` enabled.

### Iterative Development

During my development from the macOS I found using an NFS share was the easier way to
develop locally and be able to run code in the remote machine interactively and keeping
things in sync easily.

- [Network Volume Approach Overview](/docs/4-development-workflow.md#network-volume-approach-overview)
