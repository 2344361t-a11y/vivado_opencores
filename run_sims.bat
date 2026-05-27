@echo off
echo ===================================================
echo Copying speech.hex to root...
echo ===================================================
if exist wbuart32\trunk\bench\verilog\speech.hex (
    copy /y wbuart32\trunk\bench\verilog\speech.hex .
)

echo ===================================================
echo Compiling RTL and Benches...
echo ===================================================
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat wbuart32\trunk\rtl\txuart.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat wbuart32\trunk\rtl\rxuart.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat wbuart32\trunk\rtl\wbuart.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat wbuart32\trunk\rtl\ufifo.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat wbuart32\trunk\bench\verilog\helloworld.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat wbuart32\trunk\bench\verilog\echotest.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat wbuart32\trunk\bench\verilog\linetest.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat wbuart32\trunk\bench\verilog\speechfifo.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat tb_helloworld.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat tb_echotest.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat tb_linetest.v
call C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat tb_speechfifo.v

echo ===================================================
echo Elaborating Snapshots...
echo ===================================================
call C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat -top tb_helloworld -snapshot tb_helloworld_behav --relax
call C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat -top tb_echotest -snapshot tb_echotest_behav --relax
call C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat -top tb_linetest -snapshot tb_linetest_behav --relax
call C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat -top tb_speechfifo -snapshot tb_speechfifo_behav --relax

echo ===================================================
echo Running Simulations...
echo ===================================================
echo [1/4] Running helloworld...
call C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat tb_helloworld_behav -R -log helloworld_sim.log

echo [2/4] Running echotest...
call C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat tb_echotest_behav -R -log echotest_sim.log

echo [3/4] Running linetest...
call C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat tb_linetest_behav -R -log linetest_sim.log

echo [4/4] Running speechfifo...
call C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat tb_speechfifo_behav -R -log speechfifo_sim.log

echo ===================================================
echo All simulations completed!
echo ===================================================
