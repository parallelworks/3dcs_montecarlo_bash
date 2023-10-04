## 3DCS Monte Carlo Parallel Workflow

The purpose of the Simulation analysis is to measure and analyze the variation in the model.  During simulation random variation is applied to the model at the tolerances, hole-pin floats, etc. and the measures are calculated.  This process is repeated a number of times defined by the user.  The multiple results for each measure are then compiled and displayed in the Analysis Window.

This workflow implements distributed parallel executions of 3DCS monte carlo simulations.

The workflow uses the 3DCS macro executor to simulate individual monte carlo evaluations, then merges them back together as a final post-process step.