import { Status, Action, Powers, Law, Metadata, RoleLabel, Conditions, LawExecutions, BlockRange, Role, PowersExecutions } from "@/config/types"
import { wagmiConfig } from '@/config/wagmiConfig'
import { useCallback, useEffect, useRef, useState } from "react";
import { lawAbi, powersAbi, addressAnalysisAbi } from "@/config/abi";
import { GetBlockReturnType, Hex, Log, parseEventLogs, ParseEventLogsReturnType } from "viem"
import { getBlock, getPublicClient, readContract, readContracts } from "wagmi/actions";
import { bytesToParams, parseChainId, parseMetadata } from "@/config/parsers";
import { useParams } from "next/navigation";
import { useBlockNumber } from "wagmi";

export const useAddressCheck = () => {
  const [status, setStatus ] = useState<Status>("idle")
  const [error, setError] = useState<any | null>(null)
  const [analysis, setAnalysis] = useState<{category: number, explanation: string, roleId: number, analyzed: boolean} | undefined>() 
  const { chainId, powers: address } = useParams<{ chainId: string, powers: `0x${string}` }>()
  const publicClient = getPublicClient(wagmiConfig, {
    chainId: parseChainId(chainId), 
  })
  const {data: currentBlock} = useBlockNumber({
    chainId: parseChainId(chainId), 
  })
  console.log("@useAddressCheck, MAIN", {chainId, error, analysis, publicClient, status})


  const checkAddress = useCallback(async (lawId: bigint, powersAddress: `0x${string}`, userAddress: `0x${string}`) => {
    console.log("@checkAddress, waypoint 0", { lawId, powersAddress, userAddress })
    setStatus("pending")

    if (publicClient && lawId && powersAddress && userAddress) {
      try {
        // First, get the active law to find the AddressAnalysis contract address
        const lawFetched = await publicClient.readContract({ 
          abi: powersAbi,
          address: powersAddress as `0x${string}`,
          functionName: 'getActiveLaw',
          args: [lawId]
        })
        console.log("@checkAddress, waypoint 1", { lawFetched })
        
        const lawFetchedTyped = lawFetched as [`0x${string}`, `0x${string}`, boolean]
        const addressAnalysisContractAddress = lawFetchedTyped[0] // First item is the AddressAnalysis contract
        
        console.log("@checkAddress, waypoint 2", { addressAnalysisContractAddress })

        // Now call the addressAnalysis function on the AddressAnalysis contract
        const analysisResult = await publicClient.readContract({
          abi: addressAnalysisAbi,
          address: addressAnalysisContractAddress,
          functionName: 'getAddressAnalysis',
          args: [userAddress]
        })

        console.log("@checkAddress, waypoint 3", { analysisResult })
        
        const [category, explanation, roleId, analyzed] = analysisResult as [bigint, string, bigint, boolean]
        
        // Set the powers with the analysis result
        setAnalysis({
          category: Number(category),
          explanation,
          roleId: Number(roleId),
          analyzed
        })
        
        setStatus("success")
      } catch (error) {
        console.error("@checkAddress, error", error)
        setStatus("error")
        setError(error)
      }
    } else {
      setStatus("error")
      setError("Missing required parameters")
    }
  }, [publicClient])



  return {status, error, analysis, checkAddress}  
}