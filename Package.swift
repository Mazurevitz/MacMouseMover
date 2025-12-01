// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacMouseMover",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacMouseMover", targets: ["MacMouseMover"])
    ],
    targets: [
        .executableTarget(
            name: "MacMouseMover",
            path: "Sources/MacMouseMover",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Sources/MacMouseMover/Info.plist"])
            ]
        )
    ]
)
