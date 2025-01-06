

        
    function performSwap (
        address _liquidationPair,
        int Txfee,
        bool isEstimator
    ) external returns (bool success){   
        uint aucPeriod = ITpdaLiquidationPair(_liquidationPair).targetAuctionPeriod();
        uint64 aucAt = ITpdaLiquidationPair(_liquidationPair).lastAuctionAt();
        uint192 lastAucPrice=ITpdaLiquidationPair(_liquidationPair).lastAuctionPrice();
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

        uint256 wethBalance = IERC20(swapData.srcToken ).balanceOf(address(this));
        require( swapData.amountInMax < wethBalance, string(abi.encodePacked(
            "Requires more WETH in the contract. Needed: ", 
            Strings.toString( swapData.amountInMax), 
            ", Available: ", 
            Strings.toString(wethBalance)
        )));



        IERC20(swapData.srcToken).approve(address(router),  swapData.amountInMax);
            // Perform the swap
            // Perform the swap
        router.swapExactAmountOut(ITpdaLiquidationPair(_liquidationPair),
                address(this), swapData.amountOut ,  swapData.amountInMax, block.timestamp+10
            );
        uint amountRealOut = swapData.amountOut;
        address newsource=address(swapData.dstToken);
        if(swapData.sourceVault ==newsource){
            IERC20(swapData.dstToken ).approve(swapData.sourceVault, swapData.amountOut);
            // Redeem the exact amount out
            amountRealOut = IVault(swapData.sourceVault).redeem(swapData.amountOut, address(this), address(this));

            newsource = IVault(swapData.sourceVault).asset();
        }else if(swapData.sourceVault==address(0x9d7A789ED31e501303B3856A58bDD9B41b7a6077)){
                IERC20(swapData.dstToken).approve(address(AavePool), swapData.amountOut);

            uint out =  AavePool.withdraw(address(swapData.srcToken), type(uint256).max, address(this));
        // Call the WETH deposit function and send ETH
                newsource=swapData.srcToken;
                amountRealOut = out;
        }
        
        if(newsource ==_WETH_Address ){
            if(int(amountRealOut) - int(swapData.amountInMax)- int(Txfee) < 0){

                
                    require( int(amountRealOut)>Txfee,"Txfee cant be greater than AmountOut");
                    uint test = uint(int(amountRealOut)-Txfee);
                    doWETHError_Func(aucAt, aucPeriod, lastAucPrice, test);

            }

            if(isEstimator){


                    doWETHSuccess_Func(amountRealOut, swapData.amountInMax);
            }
            IERC20(newsource).transfer(msg.sender, amountRealOut-swapData.amountInMax);
            return true;
        }
        // Approve the router to spend the source token
        IERC20(newsource).approve(address(swapRouter), amountRealOut);

        // Encode data
        
            IV3SwapRouter.ExactInputSingleParams memory params =
                IV3SwapRouter.ExactInputSingleParams({
                    tokenIn: newsource,
                    tokenOut: swapData.srcToken,
                    fee: 500,
                    recipient: address(this),
                    amountIn: amountRealOut,
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
    if(int(amountOut) - int( swapData.amountInMax) -int(Txfee)<0){


                    require( int(amountOut)>Txfee,"Txfee cant be greater than AmountOut");
                    uint test = uint(int(amountOut)-Txfee);
                    doWETHError_Func(aucAt, aucPeriod, lastAucPrice, test);

        

    }

    require(int(amountOut)  >= int( swapData.amountInMax)+Txfee,"Transaction not profitable yet2");

            if(isEstimator){


                    doWETHSuccess_Func(amountOut, swapData.amountInMax);
            }
    
        IERC20(swapData.srcToken).transfer(msg.sender, amountOut- swapData.amountInMax);

        return true;
        // emit SwapPerformed(srcToken, dstToken, amountIn, returnAmount);
    }
