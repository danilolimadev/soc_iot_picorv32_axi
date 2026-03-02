def convert_to_little_endian_32bit(input_text):
    lines = input_text.strip().splitlines()
    
    base_address = None
    bytes_list = []

    # Processa linhas
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # Captura endereço
        if line.startswith("@"):
            base_address = line
        else:
            # Adiciona bytes individuais
            bytes_list.extend(line.split())

    # Verifica múltiplo de 4
    if len(bytes_list) % 4 != 0:
        raise ValueError("Quantidade de bytes não é múltipla de 4!")

    output_lines = []

    if base_address:
        output_lines.append(base_address)

    # Converte grupos de 4 bytes
    for i in range(0, len(bytes_list), 4):
        b0 = bytes_list[i]
        b1 = bytes_list[i+1]
        b2 = bytes_list[i+2]
        b3 = bytes_list[i+3]

        # Little endian (inverte ordem)
        word = b3 + b2 + b1 + b0
        output_lines.append(word.upper())

    return "\n".join(output_lines)


# ====== USO ====== 
# Coloque os dados ali, se não for multiplo de 4 adicione 00 até ser
if __name__ == "__main__":
    input_text = """
@00000000
17 11 00 00 ...
"""

    result = convert_to_little_endian_32bit(input_text)
    print(result)