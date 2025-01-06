
        
    function performSwap (
        address _liquidationPair,
        int Txfee
    ) external returns (bool success){   
        uint aucPeriod = ITpdaLiquidationPair(_liquidationPair).targetAuctionPeriod();
        uint64 aucAt = ITpdaLiquidationPair(_liquidationPair).lastAuctionAt();
        uint192 lastAucPrice=ITpdaLiquidationPair(_liquidationPair).lastAuctionPrice();
            // Transfer tokens from sender to contract
        address sourceVault= address(ILiquidationPair(_liquidationPair).source());

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



        IERC20(srcToken).approve(address(router), _amountInMax2);
            // Perform the swap
            // Perform the swap
        router.swapExactAmountOut(ITpdaLiquidationPair(_liquidationPair),
                address(this), _amountOut2, _amountInMax2, block.timestamp+10
            );
        uint amountRealOut = _amountOut2;
        address newsource=address(dstToken);
        if(sourceVault ==newsource){
            IERC20(dstToken).approve(sourceVault, _amountOut2);
            // Redeem the exact amount out
            amountRealOut = IVault(sourceVault).redeem(_amountOut2, address(this), address(this));

            newsource = IVault(sourceVault).asset();
        }else if(sourceVault==address(0x9d7A789ED31e501303B3856A58bDD9B41b7a6077)){
                IERC20(dstToken).approve(address(AavePool), _amountOut2);

            uint out =  AavePool.withdraw(address(srcToken), type(uint256).max, address(this));
        // Call the WETH deposit function and send ETH
                newsource=srcToken;
                amountRealOut = out;
        }
        
        if(newsource ==_WETH_Address ){
            if(int(amountRealOut) - int(_amountInMax2)- int(Txfee) < 0){

                
                    require( int(amountRealOut)>Txfee,"Txfee cant be greater than AmountOut");
                    uint test = uint(int(amountRealOut)-Txfee);
                    doWETHError_Func(aucAt, aucPeriod, lastAucPrice, test);

            }
            IERC20(newsource).transfer(msg.sender, amountRealOut-_amountInMax2);
            return true;
        }
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
                    uint test = uint(int(amountOut)-Txfee);
                    doWETHError_Func(aucAt, aucPeriod, lastAucPrice, test);

        

    }

    require(int(amountOut)  >= int(_amountInMax2)+Txfee,"Transaction not profitable yet2");

    
        IERC20(srcToken).transfer(msg.sender, amountOut-_amountInMax2);

        return true;
        // emit SwapPerformed(srcToken, dstToken, amountIn, returnAmount);
    }


