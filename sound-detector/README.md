# anesowa: Sound Detector

Identifies a specific sound and notifies the [Sound Distributor](/sound-distributor).

See the [Architecture](/#architecture) section on the root [README.md](/) for more.

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

### Container Development

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
  -t anesowa/sound-detector:1.0.0-dev \
  ./sound-detector
```

Then run a container as follows:

```
eulersson@macbook:~/Devel/anesowa $ docker run -it \
  --name anesowa-pyright-dev-container \
  -v $(pwd):/anesowa/sound-detector \
  --add-host dev-hack:127.0.0.1 \
  --net host \
  --hostname dev-hack \
  --entrypoint /bin/bash \
  --init \
  --detach \
  anesowa/sound-detector:1.0.0-dev
```

When you are done you working remember to stop and delete the container:

```
eulersson@macbook:~ $ docker stop --time 0 anesowa-pyright-dev-container
eulersson@macbook:~ $ docker rm anesowa-pyright-dev-container
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
    "anesowa-pyright-dev-container",
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

### Microphone & Speaker

Read the guide on [Docker Container Sound](#docker-container-sound) to make sure you
have PulseAudio installed on your host machine with the `module-native-protocol-tcp`
enabled.

### Iterative Development

During my development from the macOS I found two workflows worked well:

- [Synching Changes Manually](#rsync)
- [Sharing Volume Between Host and Rasberry Pis](#network-volume)

#### rsync

Synching the changes manually with `rsync`:

```
eulersson@macbook:~ $ rsync \
  -e "ssh -i ~/.ssh/raspberrypi_key.pub" -azhP \
  --exclude "sound-player/build/" --exclude ".git/" --exclude "*.cache*" \
  . anesowa@rpi-master.local:/home/user/anesowa
```

Then running the corresponding `docker run` volume-binding the project folder:

```
anesowa@rpi-master:~/anesowa/sound-detector $ docker run ... -v $(pwd):/anesowa/sound-detector ...
```

PROS:

- Only the changed files are synced.
- It is secure and encrypted.

CONS:

- It's a manual action.
- Only syncs towards a single target machine.
- Deleted files are not handled.

### LSP Features

#### Python

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
