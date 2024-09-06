## Run

```
1. copy folder
2. run 'switcher.ah2' script
3. double-click what you want to bind for group1 -> Assign
4. double-click what you want to bind for group2 -> Assign

5. Save settings OR Export config
Use CTRL + ` to toggle between groups 1-2
Or 
Use `CTRL + Shift + <1-5>` to toggle groups explicitly
```

---

Entry file: `switcher.ah2`

Config syntax:
```
{"<groupId1>": [<processId1>, <processId2>], "<groupId2>": [<processId3>] }
```

Filter what you want:
```
WINDOW_FILTER := "i)^(chrome|firefox|edge|explorer)\.exe$"
```

### Todo: 
- Auto-hook
