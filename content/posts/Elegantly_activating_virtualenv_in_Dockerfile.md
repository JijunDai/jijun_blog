---
title: "Elegantly activating a virtualenv in a Dockerfile"
author: "Jijun Dai"
date: 2022-12-10T02:35:45-05:00
tags:
- Development
- python
- virtualenv
- docker
---

**What activating actually does** 

It’s easy to think of `activate` as some mysterious magic, a pentacle drawn in blood to keep Python safely trapped. But it’s just software, and fairly simple software at that. [The virtualenv documentation](https://virtualenv.readthedocs.io/en/latest/userguide/#activate-script) will even tell you that `activate` is “purely a convenience.”

If you go and read the code for `activate`, it does a number of things:

1. It figures out what shell you’re running.
2. It adds a `deactivate` function to your shell, and messes around with `pydoc`.
3. It changes the shell prompt to include the virtualenv name.
4. It unsets the `PYTHONHOME` environment variable, if someone happened to set it.
5. It sets two environment variables: `VIRTUAL_ENV` and `PATH`.

The first four are basically irrelevant to Docker usage, so that just leaves the last item. Most of the time `VIRTUAL_ENV` has no effect, but some tools—e.g. the `poetry` packaging tool—use it to detect whether you’re running inside a virtualenv.

The most important part is setting `PATH`: `PATH` is a list of directories which are searched for commands to run. `activate` simply adds the virtualenv’s `bin/` directory to the start of the list.

**We can replace `activate` by setting the appropriate environment variables: Docker’s `ENV` command applies both subsequent `RUN`s as well as to the `CMD`.**

The result is the following Dockerfile:

```
FROM python:3.8-slim-buster

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install dependencies:
COPY requirements.txt .
RUN pip install -r requirements.txt

# Run the application:
COPY myapp.py .
CMD ["python", "myapp.py"]
```

The virtualenv now automatically works for both `RUN` and `CMD`, without any repetition or need to remember anything.
