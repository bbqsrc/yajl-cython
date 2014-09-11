from pyyajl import YajlContentHandler, YajlParser
from io import BytesIO

class Handler(YajlContentHandler):
    def __init__(self):
        self.tokens = []
        self.buf = BytesIO()

    def _sep(self):
        if self.tokens[-1] == '[':
            self.buf.write(b', ')

    def boolean(self, v):
        self.buf.write(b"true" if v else b"false")

    def string(self, v):
        self.buf.write(b'"%s"' % v)
        self._sep()

    def integer(self, v):
        self.buf.write(v)
        self._sep()

    def number(self, v):
        self.buf.write(v)
        self._sep()

    def start_map(self):
        self.buf.write(b'{')
        self.tokens.append('{')

    def start_array(self):
        self.buf.write(b'[')
        self.tokens.append('[')

    def end_array(self):
        self.buf.seek(0, 2)
        self.buf.seek(-2, 1)
        self.buf.truncate(self.buf.tell())
        self.buf.write(b']')
        self.tokens.pop()

    def map_key(self, v):
        vv = '"%s": ' % v.decode('utf-8')
        self.buf.write(vv.encode('utf-8'))

    def end_map(self):
        self.buf.write(b'}')
        self.tokens.pop()

        if len(self.tokens) == 0:
            print(self.buf.getvalue().decode('utf-8'))
            self.buf = BytesIO()

parser = YajlParser(Handler(), allow_multiple_values=True)
parser.parse_chunk("""{"foo": [1, 2,""")
parser.parse_chunk("""3]}{"bar": 9123}""")
parser.parse("""{"Done": true}""")

parser.parse("more")
