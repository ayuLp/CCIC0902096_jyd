import sys
import string

WIDTH = 32

RISCV_opcode_dict = {
    'next_decode' : True,
    'decode_bits' : [6, 0],

    '0110111': {
        'type': 'U',
        'opcode': 'LUI'
    },

    '0010111': {
        'type': 'U',
        'opcode': 'AUIPC'
    },

    '1101111': {
        'type': 'J',
        'opcode': 'JAL'
    },

    '1100111': {
        'type': 'I',
        'opcode': 'JALR'
    },
    
    '1100011': {
        'type': 'B',
        'opcode': 'BRANCH',
        'next_decode' : True,
        'decode_bits' : [14, 12],
        '000' : {
            'opcode': 'BEQ'
        },
        '001' : {
            'opcode': 'BNE'
        },
        '100' : {
            'opcode': 'BLT'
        },
        '101' : {
            'opcode': 'BGE'
        },
        '110' : {
            'opcode': 'BLTU'
        },
        '111' : {
            'opcode': 'BGEU'
        },
    },

    '0000011': {
        'type': 'I',
        'opcode': 'LOAD',
        'next_decode' : True,
        'decode_bits' : [14, 12],
        '000' : {
            'opcode': 'LB'
        },
        '001' : {
            'opcode': 'LH'
        },
        '010' : {
            'opcode': 'LW'
        },
        '100' : {
            'opcode': 'LBU'
        },
        '101' : {
            'opcode': 'LHU'
        }
    },

    '0100011': {
        'type': 'S',
        'opcode': 'STORE',
        'next_decode' : True,
        'decode_bits' : [14, 12],
        '000' : {
            'opcode': 'SB'
        },
        '001' : {
            'opcode': 'SH'
        },
        '010' : {
            'opcode': 'SW'
        }
    },

    '0010011': {
        'type': 'I',
        'opcode': 'Imm',
        'next_decode' : True,
        'decode_bits' : [14, 12],
        '000' : {
            'opcode': 'ADDI'
        },
        '001' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'SLLI'
            }
        },
        '010' : {
            'opcode': 'SLTI'
        },
        '011' : {
            'opcode': 'SLTIU'
        },
        '100' : {
            'opcode': 'XORI'
        },
        '101' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'SRLI'
            },
            '0100000': {
                'opcode': 'SRAI'
            }
        },
        '110' : {
            'opcode': 'ORI'
        },
        '111' : {
            'opcode': 'ANDI'
        }
    },

    '0110011': {
        'type': 'R',
        'opcode': 'Arithmetic',
        'next_decode' : True,
        'decode_bits' : [14, 12],
        '000' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'ADD'
            },
            '0100000': {
                'opcode': 'SUB'
            }
        },
        '001' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'SLL'
            }
        },
        '010' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'SLT'
            }
        },
        '011' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'SLTU'
            }
        },
        '100' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'XOR'
            }
        },
        '101' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'SRL'
            },
            '0100000': {
                'opcode': 'SRA'
            }
        },
        '110' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'OR'
            }
        },
        '111' : {
            'next_decode' : True,
            'decode_bits' : [31, 25],
            '0000000': {
                'opcode': 'AND'
            }
        }
    },

    '0001111': {
        'type': 'I_fence',
        'next_decode' : True,
        'decode_bits' : [19, 7],
        '0000000000000' : {
            'next_decode' : True,
            'decode_bits' : [31, 28],
            '0000' : {
                'opcode': 'FENCE'
            }
        }
    },

    '1110011': {
        'opcode': 'CSRs',
        'next_decode' : True,
        'decode_bits' : [14, 12],
        '000' : {
            'next_decode' : True,
            'decode_bits' : [31, 7],
            '0000000000000000000000000': {
                'opcode': 'ECALL'
            },
            '0000000000010000000000000': {
                'opcode': 'EBREAK'
            }
        },
        '001' : {
            'type': 'I',
            'opcode': 'CSRRW'
        },
        '010' : {
            'type': 'I',
            'opcode': 'CSRRS'
        },
        '011' : {
            'type': 'I',
            'opcode': 'CSRRC'
        },
        '101' : {
            'type': 'I_CSRI',
            'opcode': 'CSRRWI'
        },
        '110' : {
            'type': 'I_CSRI',
            'opcode': 'CSRRSI'
        },
        '111' : {
            'type': 'I_CSRI',
            'opcode': 'CSRRCI'
        }
    },
    
    '0110011' : {       # M-extension
        'next_decode' : True,
        'decode_bits' : [31, 25],
        '0000001' : {
            'type': 'R',
            'next_decode' : True,
            'decode_bits' : [14, 12],
            '000' : {
                'opcode' : 'MUL'
            },
            '001' : {
                'opcode': 'MULH'
            },
            '010' : {
                'opcode': 'MULHSU'
            },
            '011' : {
                'opcode': 'MULHU'
            },
            '100' : {
                'opcode': 'DIV'
            },
            '101' : {
                'opcode': 'DIVU'
            },
            '110' : {
                'opcode': 'REM'
            },
            '111' : {
                'opcode': 'REMU'
            }
        }
    },

    '0000111' : {       # V-extension Loads
        'next_decode' : True,
        'decode_bits' : [27, 26],
        '00' : {
                'type': 'VL',
                'opcode' : 'VLE'
        },
        '01' : {
                'type': 'VLX',
                'opcode' : 'VLUXEI'
        },
        '10' : {
                'type': 'VLS',
                'opcode' : 'VLSE'
        },
        '11' : {
                'type': 'VLX',
                'opcode' : 'VLOXEI'
        }
    },

    '0100111' : {       # Stores
        'next_decode' : True,
        'decode_bits' : [27, 26],
        '00' : {
                'type': 'VS',
                'opcode' : 'VSE'
        },
        '01' : {
                'type': 'VSX',
                'opcode' : 'VSUXEI'
        },
        '10' : {
                'type': 'VSS',
                'opcode' : 'VSSE'
        },
        '11' : {
                'type': 'VSX',
                'opcode' : 'VSOXEI'
        }
    },

    '1010111': {
        'next_decode' : True,
        'decode_bits' : [14, 12],
        '000' : {
            'opcode': 'OPIVV'
        },
        '001' : {
            'opcode': 'OPFVV'
        },
        '010' : {
            'opcode': 'OPMVV'
        },
        '011' : {
            'opcode': 'OPIVI'
        },
        '100' : {
            'opcode': 'OPIVX'
        },
        '101' : {
            'opcode': 'OPFVF'
        },
        '110' : {
            'opcode': 'OPMVX'
        },
        '111' : {
            'next_decode' : True,
            'decode_bits' : [31, 31],
            '0' : {
                'opcode': 'vsetvli'
            },
            '1' : {
                'next_decode' : True,
                'decode_bits' : [30, 30],
                '0': {
                    'next_decode' : True,
                    'decode_bits' : [29, 25],
                    '00000': {
                        'opcode': 'vsetvl'
                    }
                },
                '1': {
                    'opcode': 'vsetivli'
                }
            }
        }
    }

}

def decode_type(type, bin_instruction):
    result = ''
    if type == 'R':
        result += ' x'
        result += str(int(bin_instruction[WIDTH-1 - 11: WIDTH - 7], 2))
        result += ', x'
        result += str(int(bin_instruction[WIDTH-1 - 19: WIDTH - 15], 2))
        result += ', x'
        result += str(int(bin_instruction[WIDTH-1 - 24: WIDTH - 20], 2))

    elif type == 'I':
        result += ' x'
        result += str(int(bin_instruction[WIDTH-1 - 11: WIDTH - 7], 2))
        result += ', x'
        result += str(int(bin_instruction[WIDTH-1 - 19: WIDTH - 15], 2))
        result += ', '
        imm = int(bin_instruction[WIDTH-1 - 30: WIDTH - 20], 2)
        if bin_instruction[0] == '1':
            imm = -imm
        result += str(imm)
        
    elif type == 'I_shamt':
        result += ' x'
        result += str(int(bin_instruction[WIDTH-1 - 11: WIDTH - 7], 2))
        result += ', x'
        result += str(int(bin_instruction[WIDTH-1 - 19: WIDTH - 15], 2))
        result += ', '
        result += str(int(bin_instruction[WIDTH-1 - 24: WIDTH - 20], 2))

    elif type == 'S':
        result += ' x'
        result += str(int(bin_instruction[WIDTH-1 - 19: WIDTH - 15], 2))
        result += ', x'
        result += str(int(bin_instruction[WIDTH-1 - 24: WIDTH - 20], 2))
        result += ', '
        imm = int(bin_instruction[WIDTH-1 - 30: WIDTH - 25] + bin_instruction[WIDTH-1 - 11: WIDTH - 7], 2)
        if bin_instruction[0] == '1':
            imm = -imm
        result += str(imm)

    elif type == 'B':
        result += ' x'
        result += str(int(bin_instruction[WIDTH-1 - 19: WIDTH - 15], 2))
        result += ', x'
        result += str(int(bin_instruction[WIDTH-1 - 24: WIDTH - 20], 2))
        result += ', '
        imm = int(bin_instruction[WIDTH-1 - 7] + bin_instruction[WIDTH-1 - 30: WIDTH - 25] + bin_instruction[WIDTH-1 - 11: WIDTH - 8], 2) << 1
        if bin_instruction[0] == '1':
            imm = -imm
        result += str(imm)

    elif type == 'U':
        result += ' x'
        result += str(int(bin_instruction[WIDTH-1 - 11: WIDTH - 7], 2))
        result += ', '
        result += str(int(bin_instruction[WIDTH-1 - 31: WIDTH - 12], 2) << 12)

    elif type == 'J':
        result += ' x'
        result += str(int(bin_instruction[WIDTH-1 - 11: WIDTH - 7], 2))
        result += ', '
        result += str(int(bin_instruction[0] + bin_instruction[WIDTH-1 - 19: WIDTH - 12] + bin_instruction[WIDTH - 20] + bin_instruction[WIDTH-1 - 30: WIDTH - 20], 2) << 1)

    elif type == 'I_fence':

        def decode_I_fence(four_bit_input):
            decoded =''
            if four_bit_input[0] == '1':
                decoded += 'I'
            if four_bit_input[1] == '1':
                decoded += 'O'
            if four_bit_input[2] == '1':
                decoded += 'R'
            if four_bit_input[3] == '1':
                decoded += 'W'
            return decoded
        
        result += ' '
        decoded = ' ('
        imm = str(int(bin_instruction[WIDTH-1 - 27: WIDTH - 24], 2))
        decoded += decode_I_fence(imm)
        decoded += ', '
        result += imm
        result += ', '
        imm = str(int(bin_instruction[WIDTH-1 - 23: WIDTH - 20], 2))
        decoded += decode_I_fence(imm)
        decoded += ')'
        result += imm
        result += decoded
    
    elif type == 'I_CSRI':
        result += ' x'
        result += str(int(bin_instruction[WIDTH-1 - 11: WIDTH - 7], 2))
        result += ', '
        imm = int(bin_instruction[WIDTH-1 - 30: WIDTH - 20], 2)
        result += ', '
        result += str(int(bin_instruction[WIDTH-1 - 19: WIDTH - 15], 2))


    return result


def riscv_translate(hex):
    decoded_instruction = ''
    type_decoded = ''
    bin_instruction = ''
    error = 0
    dict_ptr = RISCV_opcode_dict

    if type(hex) is str:
        if(len(hex) == WIDTH/4) and all(c in string.hexdigits for c in hex):
            bin_instruction = bin(int(hex, 16))[2:].zfill(WIDTH)
        elif len(hex) == WIDTH and all(c in {'0', '1'} for c in hex):
            bin_instruction = hex
    elif type(hex) is int:
        bin_instruction = bin(hex)[2:].zfill(WIDTH)
    else:
        print('hex/bin conversion error')
        return -1
    
    while('next_decode' in dict_ptr and dict_ptr['next_decode']):
        opcode = bin_instruction[(WIDTH - 1 - dict_ptr['decode_bits'][0]): (WIDTH - dict_ptr['decode_bits'][1])]
        if 'type' in dict_ptr:
            type_decoded = decode_type(dict_ptr['type'], bin_instruction)
        if opcode in dict_ptr:
            dict_ptr = dict_ptr[opcode]
        else:
            print("ERROR: sub-code not found: " + bin_instruction)
            error = 1
            break

    if error == 1:
        decoded_instruction = 'Error: ' + bin_instruction
    else:
        decoded_instruction = dict_ptr['opcode'] + type_decoded
    print(decoded_instruction)

    # print(decoded_instruction)
    return decoded_instruction




if __name__ == "__main__":
    print("RISC-V hex to asm")

    if  len(sys.argv) < 2 or sys.argv[1][-4:] == '.hex':
        if len(sys.argv) < 2:
            hex_file_name = 'test.hex'
        else:
            hex_file_name = sys.argv[1]
        hex_file = open(hex_file_name, mode='r')

        while True:
            instruction = hex_file.readline(8)
            if instruction == '':
                break
            riscv_translate(instruction)
            if instruction[-1] != '\n':
                hex_file.readline()
    else:
        riscv_translate(sys.argv[1])
