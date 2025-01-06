

    
    function performSwap_Fixed (
        address _liquidationPair,
        int Txfee
    ) external returns (bool success){   
            // Transfer tokens from sender to contract

        address srcToken = ILiquidationPair(_liquidationPair).tokenIn();
        address dstToken = ILiquidationPair(_liquidationPair).tokenOut();


            uint _amountOut2 = ITpdaLiquidationPair(_liquidationPair).maxAmountOut();
            uint _amountInMax2 = ITpdaLiquidationPair(_liquidationPair).computeExactAmountIn(_amountOut2);

        uint256 wethBalance = IERC20(srcToken).balanceOf(address(this));
        require(_amountInMax2 < wethBalance, string(abi.encodePacked(
            "Requires more WETH in the contract. Needed: ", 
            Strings.toString(_amountInMax2), 
            ", Available: ", 
            Strings.toString(wethBalance)
        )));



        IERC20(srcToken).approve(address(fixedRouter_1), _amountInMax2);
            // Perform the swap
            // Perform the swap
        fixedRouter_1.swapExactAmountOut( ITpdaLiquidationPair(_liquidationPair), address(this), _amountOut2, _amountInMax2, block.timestamp+10);

        address newsource=address(dstToken);
    
        // Approve the router to spend the source token
        IERC20(newsource).approve(address(swapRouter), _amountOut2);

        // Encode data
        
            IV3SwapRouter.ExactInputSingleParams memory params =
                IV3SwapRouter.ExactInputSingleParams({
                    tokenIn: newsource,
                    tokenOut: srcToken,
                    fee: 500,
                    recipient: address(this),
                    amountIn: _amountOut2,
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
    if(int(amountOut) - int(_amountInMax2) -int(Txfee)<0){


                    require( int(amountOut)>Txfee,"Txfee cant be greater than AmountOut");
                    doWETHError_Func_Simple(amountOut, Txfee, _amountInMax2);

        

    }

    require(amountOut  >= _amountInMax2+uint(Txfee),"Transaction not profitable yet2");

    
        IERC20(srcToken).transfer(msg.sender, amountOut-_amountInMax2);

        return true;
        // emit SwapPerformed(srcToken, dstToken, amountIn, returnAmount);
    }

