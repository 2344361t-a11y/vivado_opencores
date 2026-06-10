[1mdiff --git a/wbuart32/trunk/rtl/GPIO/GPIO.xpr b/wbuart32/trunk/rtl/GPIO/GPIO.xpr[m
[1mindex 987c77c..51beb30 100644[m
[1m--- a/wbuart32/trunk/rtl/GPIO/GPIO.xpr[m
[1m+++ b/wbuart32/trunk/rtl/GPIO/GPIO.xpr[m
[36m@@ -58,7 +58,7 @@[m
     <Option Name="IPUserFilesDir" Val="$PIPUSERFILESDIR"/>[m
     <Option Name="IPStaticSourceDir" Val="$PIPUSERFILESDIR/ipstatic"/>[m
     <Option Name="EnableBDX" Val="FALSE"/>[m
[31m-    <Option Name="WTXSimLaunchSim" Val="0"/>[m
[32m+[m[32m    <Option Name="WTXSimLaunchSim" Val="6"/>[m
     <Option Name="WTModelSimLaunchSim" Val="0"/>[m
     <Option Name="WTQuestaLaunchSim" Val="0"/>[m
     <Option Name="WTIesLaunchSim" Val="0"/>[m
[36m@@ -111,10 +111,11 @@[m
       </Config>[m
     </FileSet>[m
     <FileSet Name="sim_1" Type="SimulationSrcs" RelSrcDir="$PSRCDIR/sim_1" RelGenDir="$PGENDIR/sim_1">[m
[31m-      <File Path="$PSRCDIR/sim_1/imports/3_gpio/tb_simplegpio.v">[m
[32m+[m[32m      <Filter Type="Srcs"/>[m
[32m+[m[32m      <File Path="$PSRCDIR/sim_1/imports/Downloads/tb_simplegpio_report_202606081631.v">[m
         <FileInfo>[m
[31m-          <Attr Name="ImportPath" Val="$PPRDIR/../../../../opencores_theme/3_gpio/tb_simplegpio.v"/>[m
[31m-          <Attr Name="ImportTime" Val="1780283059"/>[m
[32m+[m[32m          <Attr Name="ImportPath" Val="$PPRDIR/../../../../../../../../Downloads/tb_simplegpio_report_202606081631.v"/>[m
[32m+[m[32m          <Attr Name="ImportTime" Val="1780903976"/>[m
           <Attr Name="UsedIn" Val="synthesis"/>[m
           <Attr Name="UsedIn" Val="implementation"/>[m
           <Attr Name="UsedIn" Val="simulation"/>[m
[36m@@ -122,9 +123,8 @@[m
       </File>[m
       <Config>[m
         <Option Name="DesignMode" Val="RTL"/>[m
[31m-        <Option Name="TopModule" Val="simple_gpio_tb"/>[m
[32m+[m[32m        <Option Name="TopModule" Val="tb_simplegpio_report"/>[m
         <Option Name="TopLib" Val="xil_defaultlib"/>[m
[31m-        <Option Name="TopAutoSet" Val="TRUE"/>[m
         <Option Name="TransportPathDelay" Val="0"/>[m
         <Option Name="TransportIntDelay" Val="0"/>[m
         <Option Name="SelectedSimModel" Val="rtl"/>[m
[36m@@ -175,9 +175,7 @@[m
   <Runs Version="1" Minor="22">[m
     <Run Id="synth_1" Type="Ft3:Synth" SrcSet="sources_1" Part="xc7a12ticsg325-1L" ConstrsSet="constrs_1" Description="Vivado Synthesis Defaults" AutoIncrementalCheckpoint="true" WriteIncrSynthDcp="false" State="current" IncludeInArchive="true" IsChild="false" AutoIncrementalDir="$PSRCDIR/utils_1/imports/synth_1" AutoRQSDir="$PSRCDIR/utils_1/imports/synth_1" ParallelReportGen="true">[m
       <Strategy Version="1" Minor="2">[m
[31m-        <StratHandle Name="Vivado Synthesis Defaults" Flow="Vivado Synthesis 2025">[m
[31m-          <Desc>Vivado Synthesis Defaults</Desc>[m
[31m-        </StratHandle>[m
[32m+[m[32m        <StratHandle Name="Vivado Synthesis Defaults" Flow="Vivado Synthesis 2025"/>[m
         <Step Id="synth_design"/>[m
       </Strategy>[m
       <ReportStrategy Name="Vivado Synthesis Default Reports" Flow="Vivado Synthesis 2025"/>[m
[36m@@ -186,9 +184,7 @@[m
     </Run>[m
     <Run Id="impl_1" Type="Ft2:EntireDesign" Part="xc7a12ticsg325-1L" ConstrsSet="constrs_1" Description="Default settings for Implementation." AutoIncrementalCheckpoint="false" WriteIncrSynthDcp="false" State="current" SynthRun="synth_1" IncludeInArchive="true" IsChild="false" GenFullBitstream="true" AutoIncrementalDir="$PSRCDIR/utils_1/imports/impl_1" AutoRQSDir="$PSRCDIR/utils_1/imports/impl_1" ParallelReportGen="true">[m
       <Strategy Version="1" Minor="2">[m
[31m-        <StratHandle Name="Vivado Implementation Defaults" Flow="Vivado Implementation 2025">[m
[31m-          <Desc>Default settings for Implementation.</Desc>[m
[31m-        </StratHandle>[m
[32m+[m[32m        <StratHandle Name="Vivado Implementation Defaults" Flow="Vivado Implementation 2025"/>[m
         <Step Id="init_design"/>[m
         <Step Id="opt_design"/>[m
         <Step Id="power_opt_design"/>[m
