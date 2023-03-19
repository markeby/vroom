#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_fst_c.h>
#include "Vtop.h"
#include "Vtop___024root.h"

#define MAX_SIM_TIME 200
vluint64_t sim_time=0;

int main(int argc, char** argv, char** env) {
    Vtop *dut = new Vtop;

    Verilated::traceEverOn(true);
    VerilatedFstC* m_trace = new VerilatedFstC;
    dut->trace(m_trace, 5);
    m_trace->open("waves.fst");

    dut->reset = 1;

    while (sim_time < MAX_SIM_TIME) {
        dut->clk ^= 1;
        if (sim_time == 3) {
            dut->reset = 0;
        }

        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
