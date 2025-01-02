import glob

import utils

if __name__ == "__main__":
    for file in glob.glob("riscv-tests/isa/rv32ui-p-*"):
        if file.endswith(".dump"):
            continue
        # Misaligned loads and stores across word boundaries are not supported by pf32i.v
        if file == "riscv-tests/isa/rv32ui-p-ma_data":
            continue
        print(file + ".dump: ", end="")
        stdout = utils.simulate(elf_file=file)
        if "PASS" in stdout:
            print("\033[32mPASS!\033[0m")
        else:
            print("\033[31mFAIL!\033[0m")
            print(stdout)