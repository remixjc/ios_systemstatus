import AppKit
import ImageIO
import UniformTypeIdentifiers
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                        bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}
context.setFillColor(color(0.045, 0.055, 0.11))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
let panel = CGPath(roundedRect: CGRect(x: 140, y: 140, width: 744, height: 744), cornerWidth: 160, cornerHeight: 160, transform: nil)
context.addPath(panel)
context.setFillColor(color(0.12, 0.14, 0.22))
context.setStrokeColor(color(1,1,1,0.1)); context.setLineWidth(4)
context.drawPath(using: .fillStroke)
for i in 0..<3 {
    context.setFillColor([color(0.02,0.57,1), color(0.03,0.76,0.87), color(0.18,0.82,0.4)][i])
    context.fillEllipse(in: CGRect(x: 266 + i * 70, y: 735, width: 28, height: 28))
}
context.setStrokeColor(color(1,1,1,0.05)); context.setLineWidth(3)
for x in stride(from: 280, through: 780, by: 110) { context.move(to: CGPoint(x:x,y:280)); context.addLine(to:CGPoint(x:x,y:675)) }
for y in stride(from: 280, through: 675, by: 99) { context.move(to: CGPoint(x:250,y:y)); context.addLine(to:CGPoint(x:780,y:y)) }
context.strokePath()
let points: [CGPoint] = [.init(x:240,y:470),.init(x:347,y:470),.init(x:410,y:620),.init(x:487,y:337),.init(x:565,y:553),.init(x:620,y:470),.init(x:784,y:470)]
context.addLines(between: points)
context.setLineWidth(34); context.setLineCap(.round); context.setLineJoin(.round)
context.setStrokeColor(color(0.02,0.65,1)); context.strokePath()
context.setFillColor(color(0.18,0.82,0.4)); context.fillEllipse(in:CGRect(x:750,y:450,width:40,height:40))
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath:CommandLine.arguments[1]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
