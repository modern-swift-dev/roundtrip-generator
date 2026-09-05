import GeneratorBuilder
import Testing

struct RenderingTests {
    @Test func `flatten preserves child ordering and rendering`() {
        let nested = NodeList([TextNode(value: "one"), NodeList(["two", "three"])])
        let list = NodeList(["zero", nested, "four"])
        #expect(list.children.count == 5)
        #expect(list.toString() == "zeroonetwothreefour")
        #expect(NodeList([]).toString().isEmpty)
        #expect(Block { list }.toString() == "zero\none\ntwo\nthree\nfour")
    }

    @Test func `indentation preserves line ending and blank line semantics`() {
        #expect("".prepad().isEmpty)
        #expect("\n".prepad() == "    ")
        #expect("a\n\nb\n".prepad() == "    a\n    \n    b")
        #expect("a\r\nb\rc\u{2028}d".prepad(2) == "        a\n        b\n        c\n        d")
        #expect("a\nb".prepad(0) == "a\nb")
    }
}
