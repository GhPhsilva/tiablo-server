"""
Corrige a posição de um waypoint no arquivo .otbm
Uso: python fix_waypoint.py <arquivo.otbm> <nome_waypoint> <x> <y> <z>
"""

import sys
import struct

ESCAPE = 0xFD
NODE_START = 0xFE
NODE_END = 0xFF

OTBM_WAYPOINTS = 15
OTBM_WAYPOINT = 16


def unescape(data):
    """Remove bytes de escape do stream OTBM e retorna (dados_limpos, mapa_de_posições)."""
    out = bytearray()
    pos_map = []  # pos_map[i] = posição original do byte i no dado limpo
    i = 0
    while i < len(data):
        b = data[i]
        if b == ESCAPE:
            i += 1
            out.append(data[i])
            pos_map.append(i)
        elif b in (NODE_START, NODE_END):
            out.append(b)
            pos_map.append(i)
        else:
            out.append(b)
            pos_map.append(i)
        i += 1
    return bytes(out), pos_map


def find_waypoint(raw, waypoint_name):
    """
    Procura o waypoint pelo nome no binário bruto (com escapes).
    Retorna a posição no arquivo raw onde os bytes x,y,z começam.
    """
    name_bytes = waypoint_name.encode('latin-1')
    name_len = len(name_bytes)
    # string em OTBM: u16 LE (tamanho) + bytes
    name_prefix = struct.pack('<H', name_len) + name_bytes

    i = 0
    while i < len(raw) - len(name_prefix) - 5:
        # Procura a sequência do nome
        idx = raw.find(name_prefix, i)
        if idx == -1:
            return None

        # Posição dos bytes x,y,z começa logo após o nome
        pos_xyz = idx + len(name_prefix)

        # Verifica se há pelo menos 5 bytes (x u16 + y u16 + z u8)
        if pos_xyz + 5 <= len(raw):
            return pos_xyz

        i = idx + 1

    return None


def read_escaped_u16(raw, pos):
    """Lê um u16 LE do stream com possíveis escapes."""
    bytes_read = []
    i = pos
    while len(bytes_read) < 2:
        b = raw[i]
        if b == ESCAPE:
            i += 1
            bytes_read.append(raw[i])
        else:
            bytes_read.append(b)
        i += 1
    value = struct.unpack('<H', bytes(bytes_read))[0]
    return value, i


def read_escaped_u8(raw, pos):
    """Lê um u8 do stream com possíveis escapes."""
    b = raw[pos]
    if b == ESCAPE:
        return raw[pos + 1], pos + 2
    return b, pos + 1


def write_escaped_u16(value):
    """Escreve u16 LE com escape se necessário."""
    low = value & 0xFF
    high = (value >> 8) & 0xFF
    result = bytearray()
    for byte in [low, high]:
        if byte in (ESCAPE, NODE_START, NODE_END):
            result.append(ESCAPE)
        result.append(byte)
    return bytes(result)


def write_escaped_u8(value):
    """Escreve u8 com escape se necessário."""
    if value in (ESCAPE, NODE_START, NODE_END):
        return bytes([ESCAPE, value])
    return bytes([value])


def fix_waypoint(filename, waypoint_name, new_x, new_y, new_z):
    with open(filename, 'rb') as f:
        raw = bytearray(f.read())

    name_bytes = waypoint_name.encode('latin-1')
    name_prefix = struct.pack('<H', len(name_bytes)) + name_bytes

    pos_after_name = raw.find(name_prefix)
    if pos_after_name == -1:
        print(f"Waypoint '{waypoint_name}' nao encontrado no arquivo.")
        return False

    pos_after_name += len(name_prefix)

    # Ler x, y, z atuais (com suporte a escapes)
    old_x, after_x = read_escaped_u16(raw, pos_after_name)
    old_y, after_y = read_escaped_u16(raw, after_x)
    old_z, after_z = read_escaped_u8(raw, after_y)

    print(f"Waypoint '{waypoint_name}' encontrado.")
    print(f"  Posição atual:  x={old_x}, y={old_y}, z={old_z}")
    print(f"  Nova posição:   x={new_x}, y={new_y}, z={new_z}")

    # Montar novos bytes
    new_xyz = write_escaped_u16(new_x) + write_escaped_u16(new_y) + write_escaped_u8(new_z)
    old_len = after_z - pos_after_name

    # Substituir no buffer
    raw[pos_after_name:after_z] = new_xyz

    with open(filename, 'wb') as f:
        f.write(raw)

    print("Arquivo salvo com sucesso.")
    return True


if __name__ == '__main__':
    if len(sys.argv) != 6:
        print("Uso: python fix_waypoint.py <arquivo.otbm> <nome> <x> <y> <z>")
        sys.exit(1)

    filename = sys.argv[1]
    name = sys.argv[2]
    x = int(sys.argv[3])
    y = int(sys.argv[4])
    z = int(sys.argv[5])

    fix_waypoint(filename, name, x, y, z)
