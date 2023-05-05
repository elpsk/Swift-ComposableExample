## ComposableArchitecture Example

---

```
HStack(spacing: 20) {
    Button("ADD") {
        viewStore.send(.add)
    }

    Text("\(viewStore.elapsedTime)")

    Button("SUB") {
        viewStore.send(.subtract)
    }
}
```

![](ss00.png)

Reference: [https://github.com/pointfreeco/swift-composable-architecture]()
