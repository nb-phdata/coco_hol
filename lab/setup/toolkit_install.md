
## MAC INSTALL INSTRUCTIONS

### 1. Tap the toolkit repo

```bash
brew tap phdata/toolkit
```

#### 2. Install the toolkit

```bash
brew install toolkit-cli
```

### 3. Create free Toolkit account and acquire auth token here:

https://toolkit.phdata.io/tool-access?os=macos#:~:text=an%20auth%20token.-,Generate%20Auth%20Token,-Generate%20an%20auth

### 4. Set auth token in the Toolkit CLI

```bash
toolkit auth --set
```
This command will prompt you for your auth token.




## WINDOWS INSTALL INSTRUCTIONS

### 1a. Install the Toolkit in Powershell (recommended)

```bash
irm https://repo.phdata.io/toolkit-cli/install.ps1 | iex
```

### 1b. Install the Toolkit in CMD

```bash
curl -fsSL https://repo.phdata.io/toolkit-cli/install.cmd -o install.cmd && install.cmd
```

### 2. Create free Toolkit account and acquire auth token here:

https://toolkit.phdata.io/tool-access?os=macos#:~:text=an%20auth%20token.-,Generate%20Auth%20Token,-Generate%20an%20auth

### 3. Set auth token in the Toolkit CLI

```bash
toolkit auth --set
```
This command will prompt you for your auth token.