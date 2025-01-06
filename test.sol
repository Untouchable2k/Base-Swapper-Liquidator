



    
    function performSwap_Fixed (
        address _liquidationPair,
        int Txfee,
        bool isEstimator
    ) external returns (bool success){   
            // Transfer tokens from sender to contract

                // Create a struct instance to store our main swap data
        SwapData memory swapData = SwapData({
            sourceVault: address(ILiquidationPair(_liquidationPair).source()),
            srcToken: ILiquidationPair(_liquidationPair).tokenIn(),
            dstToken: ILiquidationPair(_liquidationPair).tokenOut(),
            amountOut: ITpdaLiquidationPair(_liquidationPair).maxAmountOut(),
            amountInMax: 0,
            wethBalance: 0
        });
        

            swapData.amountInMax = ITpdaLiquidationPair(_liquidationPair).computeExactAmountIn(swapData.amountOut);

        uint256 wethBalance = IERC20(swapData.srcToken).balanceOf(address(this));
        require(swapData.amountInMax < wethBalance, string(abi.encodePacked(
            "Requires more WETH in the contract. Needed: ", 
            Strings.toString(swapData.amountInMax), 
            ", Available: ", 
            Strings.toString(wethBalance)
        )));



        IERC20(swapData.srcToken).approve(address(fixedRouter_1), swapData.amountInMax);
            // Perform the swap
            // Perform the swap
        fixedRouter_1.swapExactAmountOut( ITpdaLiquidationPair(_liquidationPair), address(this), swapData.amountOut, swapData.amountInMax, block.timestamp+10);

        address newsource=address(swapData.dstToken);
    
        // Approve the router to spend the source token
        IERC20(newsource).approve(address(swapRouter), swapData.amountOut);

        // Encode data
        
            IV3SwapRouter.ExactInputSingleParams memory params =
                IV3SwapRouter.ExactInputSingleParams({
                    tokenIn: swapData.dstToken,
                    tokenOut: swapData.srcToken,
                    fee: 500,
                    recipient: address(this),
                    amountIn: swapData.amountOut,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });


        /// @notice Swaps `amountIn` of one token for as much as possible of another token
        /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
        /// and swap the entire amount, enabling contracts to send tokens before calling this function.
        /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
        /// @return amountOut The amount of the received token
            // The call to `exactInputSingle` executes the swap.
        uint amountOut = swapRouter.exactInputSingle(params);
    if(int(amountOut) - int(swapData.amountInMax) -int(Txfee)<0){


                    require( int(amountOut)>Txfee,"Txfee cant be greater than AmountOut");
                    doWETHError_Func_Simple(amountOut, Txfee, swapData.amountInMax);

        

    }

    require(amountOut  >= swapData.amountInMax+uint(Txfee),"Transaction not profitable yet2");

        if(isEstimator){
                    doWETHSuccess_Func(amountOut, swapData.amountInMax);
        }
        IERC20(swapData.srcToken).transfer(msg.sender, amountOut-swapData.amountInMax);

        return true;
        // emit SwapPerformed(srcToken, dstToken, amountIn, returnAmount);
    }
