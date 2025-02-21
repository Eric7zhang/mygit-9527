"""
def print_specific_line(file_path, line_number):
    try:
        with open(file_path, "r") as file:
            current_line = 0
            while True:
                line = file.readline()  # 逐行读取
                if not line:  # 如果读到文件末尾
                    break
                current_line += 1
                if current_line == line_number:  # 找到指定行
                    print(f"第 {line_number} 行内容: {line.strip()}")
                    return
            print(f"文件只有 {current_line} 行，未找到第 {line_number} 行。")
    except FileNotFoundError:
        print(f"文件 {file_path} 未找到。")

# 示例：打印第 3 行内容
print_specific_line("filename.txt", 3)
"""
"""
def printfileline(filename,linenumber):
    try:
        with open(filename,"r") as file:
            cline = 0
            while True:
                line = file.readline()
                if not line:
                    break
                cline += 1
                if cline <= linenumber:
                    print(f"第{cline}行,{line.strip()}")
                    #return
            print(f"文件只有{cline}行，未找到第{linenumber}行")
    except FileNotFoundError:
        print(f"文件{filename}未找到")
printfileline("filename.txt",9)
"""


