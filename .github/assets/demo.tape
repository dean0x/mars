Output .github/assets/demo.gif

Set FontSize 18
Set Width 1200
Set Height 650
Set Padding 24
Set Theme "Catppuccin Mocha"
Set WindowBar Colorful
Set TypingSpeed 40ms
Set Framerate 30

# Clean start
Hide
Type "cd $(mktemp -d) && clear"
Enter
Sleep 500ms
Show

# Step 1: Initialize workspace
Type "mars init"
Enter
Sleep 1.5s

# Type workspace name when prompted
Type "my-project"
Enter
Sleep 1s

# Step 2: Add repos with tags
Type "mars add https://github.com/dean0x/mars-example-frontend.git --tags frontend,web"
Enter
Sleep 1.5s

Type "mars add https://github.com/dean0x/mars-example-backend.git --tags backend,api"
Enter
Sleep 1.5s

Type "mars add https://github.com/dean0x/mars-example-shared.git --tags shared"
Enter
Sleep 1.5s

# Step 3: Clone all repos (spinners show per-repo progress)
Type "mars clone"
Enter
Sleep 8s

# Step 4: Check status
Type "mars status"
Enter
Sleep 2s

# Step 5: Tag filtering with exec
Type 'mars exec "git log --oneline -3" --tag frontend'
Enter
Sleep 2s

# Final pause
Sleep 2s
